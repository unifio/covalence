- Might need to namespace a little better:
```
rake all:clean                         # Clean all environments
rake all:verify                        # Verify all environments
rake ci                                # Run all CI tests
rake ci:all:verify                     # Verify all stacks
rake rspec:apply                       # Apply changes to the rspec environment
```

all, ci, and rspec will likely all conflict. Might be able to ignore the rspec rake if it's only internal to prometheus

- `ruby/lib` might need to get shuffled to `?/lib/prometheus-unifio`
- individual state-stores: would be nice if it had something to describe the backing input types
- stack caching opportunities if they're called multiple times in the rake tasks
- consider httparty vs rest-client
- local code climate might be good while i'm shuffling stuff about
- Use the invalid yaml syntax to figure out more things in rake tasks that needs to be lazy loaded
- Like the idea of maybe splitting out the syntax elements to a different gem. Gem installation & management would become easier
- missing spec around reports?
- Need to gem-friendly the namespace all under one umbrella
- Look into muting the reporter as dev default: https://github.com/ci-reporter/ci_reporter
- Look into getting HieraDB wrapper to read .yml files
- Consolidate ENV usage/definition into top level Prometheus module
