from opentelemetry._logs import Logger, SeverityNumber
import traceback




def emit_cache_client_operation_exception(
    logger: Logger,
    severity_number: SeverityNumber,
    exception: BaseException,
) -> None:
    """An exception that occurred during a cache operation"""
    _exc_type = type(exception)
    attrs = {
        "exception.message": str(exception),
        "exception.stacktrace": "".join(traceback.format_exception(type(exception), exception, exception.__traceback__)),
        "exception.type": f"{_exc_type.__module__}.{_exc_type.__qualname__}" if _exc_type.__module__ != "builtins" else _exc_type.__qualname__,
        "event.name": "cache.client.operation.exception",
    }
    logger.emit(
        event_name="cache.client.operation.exception",
        severity_number=severity_number,
        attributes={k: v for k, v in attrs.items() if v is not None},
    )
