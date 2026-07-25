# MyApp

Hand-written prose the generator must leave alone.

## Request span

<!-- weaver .registry.spans[] | select(.type == "myapp.request") -->
<!-- endweaver -->

## Request duration metric

<!-- weaver .registry.metrics[] | select(.name == "myapp.request.duration") -->
<!-- endweaver -->

## Session started event

<!-- weaver .registry.events[] | select(.name == "myapp.session.started") -->
<!-- endweaver -->

## Service entity

<!-- weaver .registry.entities[] | select(.type == "myapp.service") -->
<!-- endweaver -->
