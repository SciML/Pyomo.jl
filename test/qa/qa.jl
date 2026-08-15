using Pyomo, SciMLTesting, Test

run_qa(
    Pyomo;
    ei_kwargs = (;
        all_explicit_imports_are_public = (; ignore = (:TwicePrecision,)),
    )
)
