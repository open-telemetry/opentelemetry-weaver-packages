# MyApp

<!-- weaver .registry.spans[] | select(.type == "myapp.request") -->
<!-- endweaver -->

<!-- weaver .registry.spans[] | select(.type == "myapp.job") -->
<!-- endweaver -->

<!-- weaver .registry.metrics[] | select(.name == "myapp.request.count") -->
<!-- endweaver -->

<!-- weaver .registry.events[] | select(.name == "myapp.started") -->
<!-- endweaver -->
