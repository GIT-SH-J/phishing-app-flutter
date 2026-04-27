import math
import os
import re
import urllib.parse
from collections import Counter
from pathlib import Path
from typing import Any, Dict, List, Optional

import joblib
import numpy as np
import pandas as pd
import tldextract
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field
from xgboost import XGBClassifier

BASE_DIR = Path(__file__).resolve().parent
DEFAULT_MODEL_PATH = BASE_DIR / "models" / "xgb_final_v1.json"
DEFAULT_ARTIFACT_CANDIDATES = [
    BASE_DIR / "xgb_train_artifacts.joblib",
    BASE_DIR / "xgb_train_artifacts_v2.joblib",
    BASE_DIR / "models" / "xgb_train_artifacts.joblib",
    BASE_DIR / "models" / "xgb_train_artifacts_v2.joblib",
]

TLD_EXTRACTOR = tldextract.TLDExtract(suffix_list_urls=None)
CAT_COLS = ["url_path", "url_tld", "url_sld", "url_subdomain"]

app = FastAPI(title="smishing-xgboost-inference", version="1.0.0")

MODEL: Optional[XGBClassifier] = None
MODEL_NUM_FEATURES: int = 0
ARTIFACTS: Optional[Dict[str, Any]] = None
PIPELINE_MODE: str = "fallback_no_artifacts"


class PredictRequest(BaseModel):
    url: str = Field(..., min_length=1)
    sourceApp: Optional[str] = None
    messageText: Optional[str] = None


class PredictResponse(BaseModel):
    url: str
    score: float
    verdict: str
    modelFeatures: int
    pipeline: str
    warnings: List[str]


def normalize_url(url: str) -> str:
    u = str(url).strip().replace("[.]", ".")
    if not u.startswith(("http://", "https://")):
        u = f"http://{u}"
    return u


def entropy(s: str) -> float:
    if not s:
        return 0.0
    freq = Counter(s)
    return float(-sum((c / len(s)) * math.log2(c / len(s)) for c in freq.values()))


def parse_url_components(url: str) -> Dict[str, str]:
    try:
        u = normalize_url(url)
        parsed = urllib.parse.urlparse(u)
        host = parsed.hostname or parsed.netloc or ""
        parts = [p for p in host.split(".") if p]
        return {
            "url_path": parsed.path or "",
            "url_tld": parts[-1] if len(parts) >= 1 else "",
            "url_sld": parts[-2] if len(parts) >= 2 else "",
            "url_subdomain": ".".join(parts[:-2]) if len(parts) > 2 else "",
        }
    except Exception:
        return {"url_path": "", "url_tld": "", "url_sld": "", "url_subdomain": ""}


def extract_features(url: str) -> Dict[str, float]:
    u = normalize_url(url)
    parsed = urllib.parse.urlparse(u)
    ext = TLD_EXTRACTOR(u)

    registered_domain = ext.top_domain_under_public_suffix or ""
    subdomain = ext.subdomain or ""
    full_domain = parsed.netloc or ""
    path = parsed.path or ""

    trusted_registered = [
        "google.com",
        "youtube.com",
        "naver.com",
        "kakao.com",
        "daum.net",
        "samsung.com",
        "microsoft.com",
        "apple.com",
        "facebook.com",
        "instagram.com",
        "twitter.com",
        "github.com",
        "wikipedia.org",
        "netflix.com",
        "amazon.com",
        "linkedin.com",
    ]

    is_trusted = 1 if registered_domain in trusted_registered else 0
    spoofing = 1 if any(td.split(".")[0] in subdomain for td in trusted_registered) else 0

    features = {
        "url_length": float(len(u)),
        "domain_length": float(len(full_domain)),
        "registered_domain_length": float(len(registered_domain)),
        "path_length": float(len(path)),
        "num_dots": float(u.count(".")),
        "num_hyphens": float(u.count("-")),
        "num_underscores": float(u.count("_")),
        "num_slashes": float(u.count("/")),
        "num_at": float(u.count("@")),
        "num_question": float(u.count("?")),
        "num_equals": float(u.count("=")),
        "num_ampersand": float(u.count("&")),
        "num_percent": float(u.count("%")),
        "has_https": float(1 if parsed.scheme == "https" else 0),
        "has_ip": float(1 if re.match(r"^\d+\.\d+\.\d+\.\d+$", parsed.hostname or "") else 0),
        "num_subdomains": float(len(subdomain.split(".")) if subdomain else 0),
        "has_port": float(1 if ":" in full_domain else 0),
        "has_suspicious_keyword": float(
            1
            if any(
                kw in u.lower()
                for kw in [
                    "login",
                    "secure",
                    "account",
                    "update",
                    "bank",
                    "verify",
                    "password",
                    "confirm",
                    "signin",
                    "free",
                    "lucky",
                    "prize",
                    "win",
                    "click",
                    "urgent",
                ]
            )
            else 0
        ),
        "is_shortened": float(1 if registered_domain in ["bit.ly", "tinyurl.com", "goo.gl", "t.co", "short.io"] else 0),
        "digit_ratio": float(sum(c.isdigit() for c in u) / len(u) if u else 0),
        "is_trusted_domain": float(is_trusted),
        "is_spoofing": float(spoofing),
        "domain_has_digit": float(1 if re.search(r"\d", registered_domain) else 0),
        "domain_has_hyphen": float(1 if "-" in registered_domain else 0),
        "tld_suspicious": float(
            1
            if any(
                registered_domain.endswith(tld)
                for tld in [".click", ".xyz", ".top", ".pw", ".tk", ".ml", ".ga", ".cf", ".gq"]
            )
            else 0
        ),
        "punycode": float(1 if "xn--" in full_domain else 0),
        "path_depth": float(path.count("/")),
        "query_length": float(len(parsed.query)),
        "num_params": float(len(parsed.query.split("&")) if parsed.query else 0),
        "subdomain_is_numeric": float(1 if subdomain.replace(".", "").isdigit() else 0),
        "domain_entropy": float(round(entropy(registered_domain), 4)),
    }
    return features


def _resolve_artifact_path() -> Optional[Path]:
    env_path = os.getenv("XGB_ARTIFACTS_PATH", "").strip()
    if env_path:
        p = Path(env_path)
        if p.exists():
            return p

    for c in DEFAULT_ARTIFACT_CANDIDATES:
        if c.exists():
            return c
    return None


def _lookup(mapping: Any, key: str, default: float) -> float:
    if mapping is None:
        return float(default)
    try:
        value = mapping.get(key, default)
    except Exception:
        return float(default)

    if value is None:
        return float(default)
    try:
        if pd.isna(value):
            return float(default)
    except Exception:
        pass
    return float(value)


def _build_feature_matrix(url: str) -> tuple[np.ndarray, List[str]]:
    warnings: List[str] = []
    feat = extract_features(url)

    if ARTIFACTS:
        try:
            numeric_feature_names: List[str] = ARTIFACTS["numeric_feature_names"]
            scaler = ARTIFACTS["scaler"]
            binary_encoder = ARTIFACTS["binary_encoder"]
            global_mean = float(ARTIFACTS.get("global_mean_train", 0.0))
            map_tld_full = ARTIFACTS.get("map_tld_full")
            map_sld_full = ARTIFACTS.get("map_sld_full")

            comp = parse_url_components(url)
            te_tld = _lookup(map_tld_full, comp["url_tld"], global_mean)
            te_sld = _lookup(map_sld_full, comp["url_sld"], global_mean)

            x_num = np.array(
                [[float(feat.get(k, 0.0)) for k in numeric_feature_names] + [te_tld, te_sld]],
                dtype=np.float32,
            )
            x_num_scaled = scaler.transform(x_num)

            x_cat_df = pd.DataFrame([[comp.get(c, "") for c in CAT_COLS]], columns=CAT_COLS).fillna("")
            x_cat_enc = binary_encoder.transform(x_cat_df).to_numpy(dtype=np.float32)

            x = np.hstack([x_num_scaled, x_cat_enc]).astype(np.float32)
            if x.shape[1] != MODEL_NUM_FEATURES:
                warnings.append(
                    f"Feature count mismatch (pipeline={x.shape[1]}, model={MODEL_NUM_FEATURES}); fallback padding applied"
                )
                x_fixed = np.zeros((1, MODEL_NUM_FEATURES), dtype=np.float32)
                copy_len = min(MODEL_NUM_FEATURES, x.shape[1])
                x_fixed[:, :copy_len] = x[:, :copy_len]
                x = x_fixed
            return x, warnings
        except Exception as exc:
            warnings.append(f"Artifacts loaded but preprocessing failed: {exc}")

    base_values = list(feat.values()) + [0.0, 0.0]
    x = np.zeros((1, MODEL_NUM_FEATURES), dtype=np.float32)
    copy_len = min(len(base_values), MODEL_NUM_FEATURES)
    x[0, :copy_len] = np.array(base_values[:copy_len], dtype=np.float32)
    warnings.append("Artifacts not found; using fallback feature vector (accuracy may be degraded)")
    return x, warnings


def _load_resources() -> None:
    global MODEL, MODEL_NUM_FEATURES, ARTIFACTS, PIPELINE_MODE

    model_path = Path(os.getenv("XGB_MODEL_PATH", str(DEFAULT_MODEL_PATH))).resolve()
    if not model_path.exists():
        raise RuntimeError(f"Model file not found: {model_path}")

    model = XGBClassifier()
    model.load_model(str(model_path))

    MODEL = model
    MODEL_NUM_FEATURES = model.get_booster().num_features()

    artifact_path = _resolve_artifact_path()
    if artifact_path:
        ARTIFACTS = joblib.load(artifact_path)
        PIPELINE_MODE = "full_artifacts"
    else:
        ARTIFACTS = None
        PIPELINE_MODE = "fallback_no_artifacts"


@app.on_event("startup")
def _startup() -> None:
    _load_resources()


@app.get("/health")
def health() -> Dict[str, Any]:
    return {
        "ok": MODEL is not None,
        "pipeline": PIPELINE_MODE,
        "modelFeatures": MODEL_NUM_FEATURES,
        "artifactsLoaded": ARTIFACTS is not None,
    }


@app.post("/predict", response_model=PredictResponse)
def predict(req: PredictRequest) -> PredictResponse:
    if MODEL is None:
        raise HTTPException(status_code=500, detail="Model not loaded")

    normalized = normalize_url(req.url)
    x, warn = _build_feature_matrix(normalized)

    try:
        score = float(MODEL.predict_proba(x)[0][1])
    except Exception as exc:
        raise HTTPException(status_code=500, detail=f"Prediction failed: {exc}")

    if score >= 0.8:
        verdict = "malicious"
    elif score >= 0.5:
        verdict = "suspicious"
    else:
        verdict = "safe"

    return PredictResponse(
        url=normalized,
        score=round(score, 6),
        verdict=verdict,
        modelFeatures=MODEL_NUM_FEATURES,
        pipeline=PIPELINE_MODE,
        warnings=warn,
    )
