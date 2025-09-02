package com.nicevideo.common.exception;

import com.nicevideo.common.result.Result;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.BindException;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import javax.validation.ConstraintViolation;
import javax.validation.ConstraintViolationException;
import java.util.stream.Collectors;

/**
 * 全局异常处理器
 */
@Slf4j
@RestControllerAdvice
public class GlobalExceptionHandler {
    
    /**
     * 处理业务异常 - 正确设置HTTP状态码
     */
    @ExceptionHandler(BusinessException.class)
    public ResponseEntity<Result<Void>> handleBusinessException(BusinessException e) {
        String message = e.getMessage();
        Integer code = e.getCode();
        
        log.warn("业务异常: {} (错误码: {})", message, code);
        
        // 根据业务异常的错误码设置对应的HTTP状态码
        HttpStatus httpStatus = mapToHttpStatus(code);
        Result<Void> result = Result.error(code, message);
        
        return ResponseEntity.status(httpStatus).body(result);
    }
    
    /**
     * 将业务错误码映射为HTTP状态码
     */
    private HttpStatus mapToHttpStatus(Integer code) {
        if (code == null) {
            return HttpStatus.INTERNAL_SERVER_ERROR;
        }
        
        switch (code) {
            case 400:
                return HttpStatus.BAD_REQUEST;
            case 401:
                return HttpStatus.UNAUTHORIZED;
            case 403:
                return HttpStatus.FORBIDDEN;
            case 404:
                return HttpStatus.NOT_FOUND;
            case 409:
                return HttpStatus.CONFLICT;
            case 422:
                return HttpStatus.UNPROCESSABLE_ENTITY;
            case 500:
                return HttpStatus.INTERNAL_SERVER_ERROR;
            case 502:
                return HttpStatus.BAD_GATEWAY;
            case 503:
                return HttpStatus.SERVICE_UNAVAILABLE;
            case 504:
                return HttpStatus.GATEWAY_TIMEOUT;
            default:
                // 对于4xx范围的错误码，使用BAD_REQUEST
                if (code >= 400 && code < 500) {
                    return HttpStatus.BAD_REQUEST;
                }
                // 对于5xx范围的错误码，使用INTERNAL_SERVER_ERROR
                else if (code >= 500 && code < 600) {
                    return HttpStatus.INTERNAL_SERVER_ERROR;
                }
                // 其他情况默认使用BAD_REQUEST
                else {
                    return HttpStatus.BAD_REQUEST;
                }
        }
    }
    
    /**
     * 处理参数校验异常
     */
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public Result<Void> handleMethodArgumentNotValidException(MethodArgumentNotValidException e) {
        String message = e.getBindingResult().getFieldErrors().stream()
                .map(FieldError::getDefaultMessage)
                .collect(Collectors.joining(", "));
        log.error("参数校验异常: {}", message);
        return Result.error(400, message);
    }
    
    /**
     * 处理绑定异常
     */
    @ExceptionHandler(BindException.class)
    public Result<Void> handleBindException(BindException e) {
        String message = e.getFieldErrors().stream()
                .map(FieldError::getDefaultMessage)
                .collect(Collectors.joining(", "));
        log.error("绑定异常: {}", message);
        return Result.error(400, message);
    }
    
    /**
     * 处理约束违反异常
     */
    @ExceptionHandler(ConstraintViolationException.class)
    public Result<Void> handleConstraintViolationException(ConstraintViolationException e) {
        String message = e.getConstraintViolations().stream()
                .map(ConstraintViolation::getMessage)
                .collect(Collectors.joining(", "));
        log.error("约束违反异常: {}", message);
        return Result.error(400, message);
    }
    
    /**
     * 处理其他异常
     */
    @ExceptionHandler(Exception.class)
    public Result<Void> handleException(Exception e) {
        log.error("系统异常", e);
        return Result.error("系统异常，请联系管理员");
    }
}

