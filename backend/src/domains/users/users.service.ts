import { prisma } from "../../db/prisma";

// UsersService는 "유저 정보"와 관련된 비즈니스 로직을 담당합니다.
export class UsersService {
  async getMe(userId: string) {
    // Prisma 스키마에서 User.id는 BigInt이므로 문자열로 들어온 userId를 BigInt로 변환합니다.
    const id = BigInt(userId);
    const user = await prisma.user.findUnique({
      where: { id },
      select: {
        id: true,
        role: true,
        localAuth: { select: { email: true } },
        socialAuth: { select: { provider: true, providerId: true } },
      },
    });

    if (!user) {
      const err = new Error("User not found");
      (err as any).statusCode = 404;
      throw err;
    }

    return {
      id: user.id.toString(),
      role: user.role,
      email: user.localAuth?.email ?? null,
      // Prisma 타입 생성 여부/버전에 따라 모델 타입 export가 달라질 수 있어서,
      // 여기서는 필요한 필드만 사용하도록 최소 단위로 처리합니다.
      socials: user.socialAuth.map((s: any) => ({
        provider: s.provider,
        provider_id: s.providerId,
      })),
    };
  }

  async deleteMe(userId: string) {
    const id = BigInt(userId);
    // 현재 DB 스키마에는 소프트 딜리트용 컬럼이 없어서 "완전 삭제"로 구현했습니다.
    // 소프트 딜리트를 원하면 users 테이블에 deletedAt 같은 컬럼을 추가하고 update로 변경하면 됩니다.
    await prisma.user.delete({ where: { id } });
    return { deleted: true };
  }
}

