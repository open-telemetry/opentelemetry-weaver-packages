from contextlib import AbstractContextManager
from typing import Optional
from opentelemetry.trace import Tracer, Span, SpanKind



from .attributes import CACHE_OPERATION_NAME

def start_cache_client_operation(
    tracer: Tracer,
    name: str,
    cache_operation_name: str,
) -> AbstractContextManager[Span]:
    """Describes a cache operation"""
    attrs = {
        CACHE_OPERATION_NAME: cache_operation_name,
    }
    return tracer.start_as_current_span(
        name,
        kind=SpanKind.CLIENT,
        attributes={k: v for k, v in attrs.items() if v is not None},
    )
