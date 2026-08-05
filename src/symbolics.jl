struct PyomoVar <: Real
    x::Py
end

PythonCall.Py(x::T) where {T <: PyomoVar} = x.x
PythonCall.pyconvert(::Type{T}, x::Py) where {T <: PyomoVar} = T(x)

Base.hash(C::PyomoVar, x::UInt) = hash(pystr(C.x), x)
Base.convert(T::Type{PyomoVar}, x::Number) = T(Py(x))
Base.promote_rule(::Type{PyomoVar}, ::Type{S}) where {S <: Number} = PyomoVar

const MaybeSymbolic = Union{Num, SymbolicT}

# Shape counterpart of `promote_symtype`: with no method the term's shape falls back to
# `Unknown(-1)`, and scalar operations then reject it ("Invalid shapes for cos"). Pyomo
# values are always scalar here. `@register_symbolic` emits this for the `py_*` functions,
# but terms built by hand need it spelled out.
_scalar_shape() = SymbolicUtils.ShapeVecT()

"""
    pyomo_getindex(v, args...)

Index into the Pyomo object `v`, which may be a [`PyomoVar`](@ref), a raw `Py`, or a
symbolic value of symtype `PyomoVar`. Unlike `getindex`, arbitrary index values (strings,
floats, symbolic values) are allowed, matching Pyomo's indexing. If `v` or any index is
symbolic the access is deferred into the expression tree and a symbolic value of symtype
`PyomoVar` is returned.
"""
function pyomo_getindex(v::Union{PyomoVar, Py, MaybeSymbolic}, args...)
    return if v isa MaybeSymbolic || any(a -> a isa MaybeSymbolic, args)
        wrap(SymbolicUtils.term(pyomo_getindex, unwrap(v), unwrap.(args)...; type = PyomoVar))
    elseif v isa PyomoVar
        v.x[args...]
    else
        v[args...]
    end
end
SymbolicUtils.promote_symtype(::typeof(pyomo_getindex), X, ii...) = PyomoVar
SymbolicUtils.promote_shape(::typeof(pyomo_getindex), shs::SymbolicUtils.ShapeT...) = _scalar_shape()

Base.getindex(v::PyomoVar, i, args...) = pyomo_getindex(v, i, args...)
# `PyomoVar <: Real`, so the all-integer case is ambiguous with `getindex(::Number, ::Integer...)`
Base.getindex(v::PyomoVar, i::Integer, args::Vararg{Integer}) = pyomo_getindex(v, i, args...)

_getproperty(s, ::Val{name}) where {name} = getproperty(s, name)
SymbolicUtils.promote_symtype(::typeof(_getproperty), M, N) = PyomoVar
SymbolicUtils.promote_shape(::typeof(_getproperty), shs::SymbolicUtils.ShapeT...) = _scalar_shape()

"""
    pysym_getproperty(s, name::Symbol)

Symbolic property access on a symbolic [`ConcreteModel`](@ref) `s`, e.g. the `U` in
`m.U[i, t]`. Pyomo components live on the underlying Python object rather than being Julia
fields, so the access cannot go through Symbolics' struct support and is instead deferred
into the expression tree as a value of symtype [`PyomoVar`](@ref).
"""
function pysym_getproperty(s::MaybeSymbolic, name::Symbol)
    return wrap(SymbolicUtils.term(_getproperty, unwrap(s), Val{name}(); type = PyomoVar))
end

-(x::C) where {C <: PyomoVar} = C(x.x.__neg__())
+(x::C, y::Real) where {C <: PyomoVar} = C(pyadd(Py(x), y))
*(x::C, y::Real) where {C <: PyomoVar} = C(pymul(Py(x), y))
-(x::C, y::Real) where {C <: PyomoVar} = C(pysub(Py(x), y))
/(x::C, y::Real) where {C <: PyomoVar} = C(pytruediv(Py(x), y))
^(x::C, y::Real) where {C <: PyomoVar} = C(pypow(Py(x), y))
^(x::C, y::Integer) where {C <: PyomoVar} = C(pypow(Py(x), y))

# Comparisons build Pyomo relational expressions, so they go through Python's operators
# rather than Julia's. The `Real` operand is promoted to a PyomoVar first via `convert`.
>=(x::C, y::C) where {C <: PyomoVar} = C(pyge(Py(x), Py(y)))
>(x::C, y::C) where {C <: PyomoVar} = C(pygt(Py(x), Py(y)))
<=(x::C, y::C) where {C <: PyomoVar} = C(pyle(Py(x), Py(y)))
<(x::C, y::C) where {C <: PyomoVar} = C(pylt(Py(x), Py(y)))
==(x::C, y::C) where {C <: PyomoVar} = C(pyeq(Py(x), Py(y)))

function _compare_expressions(x::PyomoVar, y::Number)
    return pyconvert(Bool, Pyomo.compare_expressions(Py(x), Py(y)))
end
Base.isequal(x::C, y::Number) where {C <: PyomoVar} = _compare_expressions(x, y)
# Resolves ambiguity with `isequal(::Real, ::AbstractFloat)`
Base.isequal(x::C, y::AbstractFloat) where {C <: PyomoVar} = _compare_expressions(x, y)
Base.iszero(x::C) where {C <: PyomoVar} = false
Base.isone(x::C) where {C <: PyomoVar} = false
Base.isfinite(x::C) where {C <: PyomoVar} = true
# A PyomoVar wraps an opaque Pyomo expression, so nothing about its value is known;
# SymbolicUtils asks this before taking integer-specific simplification paths.
Base.isinteger(x::C) where {C <: PyomoVar} = false
SymbolicUtils.isnegative(x::C) where {C <: PyomoVar} = false

for ff in [acos, acosh, asin, tan, atanh, cos, log, sin, log10, sqrt, exp]
    f = nameof(ff)
    @eval NaNMath.$f(x::PyomoVar) = PyomoVar(pyomo.$f(Py(x)))
    py_f = Symbol(:py_, f)
    @eval $py_f(x) = pyomo.$f(x)
end
@register_symbolic py_acos(x::PyomoVar)
@register_symbolic py_acosh(x::PyomoVar)
@register_symbolic py_asin(x::PyomoVar)
@register_symbolic py_tan(x::PyomoVar)
@register_symbolic py_atanh(x::PyomoVar)
@register_symbolic py_cos(x::PyomoVar)
@register_symbolic py_log(x::PyomoVar)
@register_symbolic py_sin(x::PyomoVar)
@register_symbolic py_sqrt(x::PyomoVar)
@register_symbolic py_exp(x::PyomoVar)
@register_symbolic py_log10(x::PyomoVar)
