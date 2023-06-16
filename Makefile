
BROWSER=firefox

help:  ## This help message.
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
	awk 'BEGIN {FS = ":.*?## "}; \
	{printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

format:  ## Format all julia files.
	julia --project=@. --eval 'using Pkg; \
		Pkg.add("JuliaFormatter"); \
		using JuliaFormatter; \
		format(".");'

.PHONY: test
test:  ## Run the tests
	julia --project=@. --eval 'using Pkg; \
		Pkg.Registry.update(); \
		Pkg.update(); \
		Pkg.test()'

.PHONY: docs
docs:  ## Generate the documentation.
	julia --project=docs --eval 'using Pkg; \
		Pkg.instantiate(); \
		Pkg.update()'
	julia --project=docs docs/make.jl

show:  ## Open the documentation on a browser.
	$(BROWSER) docs/build/index.html

clean:  ## Remove the JuliaFormatter from Project.toml.
	julia --project=@. --eval 'using Pkg; \
		Pkg.rm("JuliaFormatter")'

run:
	docker run -itv .:/home/code --rm --network host --entrypoint bash -w /home/code julia:1.9