# Jobs

Several snippets on one page: footnote ids are scoped by definition, so they do
not collide even though each snippet restarts at [1].

<!-- weaver .registry.metrics[] | select(.name == "myapp.job.duration") -->
<!-- endweaver -->

<!-- weaver .registry.metrics[] | select(.name == "myapp.job.count") -->
<!-- endweaver -->

<!-- weaver .registry.spans[] | select(.type == "myapp.job.run") -->
<!-- endweaver -->

<!-- weaver .registry.entities[] | select(.type == "myapp.job.run") -->
<!-- endweaver -->

<!-- weaver .registry.events[] | select(.name == "myapp.job.failed") -->
<!-- endweaver -->

<!-- weaver .registry.attribute_groups[] | select(.id == "myapp.job") -->
<!-- endweaver -->
