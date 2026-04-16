import { PrismaClient } from "@prisma/client";

// 애플리케이션 전역에서 공유하는 PrismaClient 인스턴스.
// 요청마다 새로 만들지 않고(커넥션 폭증 방지) 하나만 재사용합니다.
export const prisma = new PrismaClient();

