from typing import Final, Optional
from opentelemetry.metrics import Meter
from .attributes import CACHE_OPERATION_NAME, CACHE_MISS

CACHE_CLIENT_OPERATION_ACTIVE: Final = "cache.client.operation.active"
"""
Number of active cache operations in progress.
Instrument: updowncounter
Unit: {operation}
"""

class CacheClientOperationActive:
    """
Number of active cache operations in progress.
Instrument: updowncounter
Unit: {operation}
    """
    def __init__(self, meter: Meter) -> None:
        self._instrument = meter.create_up_down_counter(
            name=CACHE_CLIENT_OPERATION_ACTIVE,
            description="Number of active cache operations in progress.",
            unit="{operation}",
        )

    def add(
        self,
        amount: int,
        cache_operation_name: str,
        server_address: Optional[str] = None,
        server_port: Optional[int] = None,
    ) -> None:
        """Number of active cache operations in progress."""
        attrs = {
            CACHE_OPERATION_NAME: cache_operation_name,
            "server.address": server_address,
            "server.port": server_port,
        }
        self._instrument.add(amount, attributes={k: v for k, v in attrs.items() if v is not None})


CACHE_CLIENT_OPERATION_DURATION: Final = "cache.client.operation.duration"
"""
Duration of cache operations.
Instrument: histogram
Unit: s
"""

class CacheClientOperationDuration:
    """
Duration of cache operations.
Instrument: histogram
Unit: s
    """
    def __init__(self, meter: Meter) -> None:
        self._instrument = meter.create_histogram(
            name=CACHE_CLIENT_OPERATION_DURATION,
            description="Duration of cache operations.",
            unit="s",
        )

    def record(
        self,
        amount: float,
        cache_operation_name: str,
        cache_miss: Optional[bool] = None,
        error_type: Optional[str] = None,
        server_address: Optional[str] = None,
        server_port: Optional[int] = None,
    ) -> None:
        """Duration of cache operations."""
        attrs = {
            CACHE_MISS: cache_miss,
            CACHE_OPERATION_NAME: cache_operation_name,
            "error.type": error_type,
            "server.address": server_address,
            "server.port": server_port,
        }
        self._instrument.record(amount, attributes={k: v for k, v in attrs.items() if v is not None})
