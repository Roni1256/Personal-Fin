import type { ErrorRequestHandler, NextFunction, Request, Response } from 'express';
import { ZodError } from 'zod';
import mongoose from 'mongoose';

export class ApiError extends Error {
  constructor(
    public readonly status: number,
    public readonly title: string,
    message: string,
    public readonly type = 'about:blank',
  ) {
    super(message);
  }
}

export function notFound(_request: Request, _response: Response, next: NextFunction): void {
  next(new ApiError(404, 'Not Found', 'The requested resource was not found.'));
}

export const errorHandler: ErrorRequestHandler = (error, request, response, _next) => {
  if (response.headersSent) return;
  let problem: ApiError;
  if (error instanceof ApiError) {
    problem = error;
  } else if (error instanceof ZodError) {
    problem = new ApiError(400, 'Validation Error', 'The request did not satisfy the API schema.');
  } else if (error instanceof mongoose.Error.ValidationError || error instanceof mongoose.Error.CastError) {
    problem = new ApiError(400, 'Invalid Data', 'The request contains invalid data.');
  } else if (error instanceof mongoose.mongo.MongoServerError && error.code === 11000) {
    problem = new ApiError(409, 'Conflict', 'A record with the same unique value already exists.');
  } else {
    console.error({ requestId: response.getHeader('x-request-id'), error });
    problem = new ApiError(500, 'Internal Server Error', 'An unexpected error occurred.');
  }

  response.status(problem.status).type('application/problem+json').json({
    type: problem.type,
    title: problem.title,
    status: problem.status,
    detail: problem.message,
    instance: request.originalUrl,
    requestId: response.getHeader('x-request-id'),
  });
};
