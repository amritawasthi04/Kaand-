import { handleOptions } from '../../../lib/utils/cors';
import { successResponse, errorResponse } from '../../../lib/utils/response';

export async function OPTIONS() {
  return handleOptions();
}

export async function GET() {
  try {
    return successResponse({
      status: 'ok',
      timestamp: new Date().toISOString(),
    });
  } catch (err: any) {
    return errorResponse(err.message || 'Internal server error', 'HEALTH_CHECK_FAILED');
  }
}
