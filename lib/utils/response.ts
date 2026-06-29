import { NextResponse } from 'next/server';
import { withCors } from './cors';

export function successResponse(data: any, status = 200) {
  const res = NextResponse.json({
    success: true,
    message: 'Success',
    code: 'SUCCESS',
    data,
  }, { status });
  return withCors(res);
}

export function errorResponse(message: string, code = 'ERROR', status = 500) {
  const res = NextResponse.json({
    success: false,
    message,
    code,
    data: null,
  }, { status });
  return withCors(res);
}
