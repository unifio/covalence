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
