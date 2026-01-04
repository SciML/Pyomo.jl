struct PyomoVar <: Real
    x::Py
end

PythonCall.Py(x::T) where {T <: PyomoVar} = x.x
PythonCall.pyconvert(::Type{T}, x::Py) where {T <: PyomoVar} = T(x)

Base.hash(C::PyomoVar, x::UInt) = hash(pystr(C.x), x)
Base.convert(T::Type{PyomoVar}, x::Number) = T(Py(x))
Base.promote_rule(::Type{PyomoVar}, ::Type{S}) where {S <: Number} = PyomoVar

# Symbolic indexing
Base.getindex(v::PyomoVar, i::Vararg{Integer}) = pyomo_getindex(v, i...)
function Base.getindex(v::Union{PyomoVar, BasicSymbolic{Struct{PyomoVar}}}, args...)
    return if v isa BasicSymbolic || any(t -> t <: Union{Num, Symbolic}, typeof(args).types)
        wrap(Term{PyomoVar}(pyomo_getindex, [v, args...]))
    else
        pyomo_getindex(v, args...)
    end
end

# Special get index method that supports arbitrary indices (strings, floats, etc.), as in pyomo
pyomo_getindex(v::PyomoVar, args...) = v.x[args...]
pyomo_getindex(v::Py, args...) = v[args...]
SymbolicUtils.promote_symtype(::typeof(pyomo_getindex), X, ii...) = PyomoVar

-(x::C) where {C <: PyomoVar} = C(x.x.__neg__())
+(x::C, y::Real) where {C <: PyomoVar} = C(pyadd(Py(x), y))
*(x::C, y::Real) where {C <: PyomoVar} = C(pymul(Py(x), y))
-(x::C, y::Real) where {C <: PyomoVar} = C(pysub(Py(x), y))
/(x::C, y::Real) where {C <: PyomoVar} = C(pydiv(Py(x), y))
^(x::C, y::Real) where {C <: PyomoVar} = C(pypow(Py(x), y))
^(x::C, y::Integer) where {C <: PyomoVar} = C(pypow(Py(x), y))

_float_if_irrational(x::Real) = x isa Irrational ? float(x) : x

>=(x::C, y::C) where {C <: PyomoVar} = C(pycall(≥, x, _float_if_irrational(y)))
>(x::C, y::C) where {C <: PyomoVar} = C(pycall(>, x, _float_if_irrational(y)))
<=(x::C, y::C) where {C <: PyomoVar} = C(pycall(≤, x, _float_if_irrational(y)))
<(x::C, y::C) where {C <: PyomoVar} = C(pycall(<, x, _float_if_irrational(y)))
==(x::C, y::C) where {C <: PyomoVar} = C(pycall(==, x, _float_if_irrational(y)))

function Base.isequal(x::C, y::Number) where {C <: PyomoVar}
    return pyconvert(Bool, pycall(Pyomo.compare_expressions, x, y))
end
Base.iszero(x::C) where {C <: PyomoVar} = false
Base.isone(x::C) where {C <: PyomoVar} = false
Base.isfinite(x::C) where {C <: PyomoVar} = true
SymbolicUtils.isnegative(x::C) where {C <: PyomoVar} = false

for ff in [acos, acosh, asin, tan, atanh, cos, log, sin, log10, sqrt, exp]
    f = nameof(ff)
    @eval NaNMath.$f(x::PyomoVar) = PyomoVar(pycall($f, x))
    py_f = Symbol(:py_, f)
    @eval $py_f(x) = pyomo.$f(x)
end
@register_symbolic py_acos(x::Symbolics.Struct{PyomoVar})
@register_symbolic py_acosh(x::Symbolics.Struct{PyomoVar})
@register_symbolic py_asin(x::Symbolics.Struct{PyomoVar})
@register_symbolic py_tan(x::Symbolics.Struct{PyomoVar})
@register_symbolic py_atanh(x::Symbolics.Struct{PyomoVar})
@register_symbolic py_cos(x::Symbolics.Struct{PyomoVar})
@register_symbolic py_log(x::Symbolics.Struct{PyomoVar})
@register_symbolic py_sin(x::Symbolics.Struct{PyomoVar})
@register_symbolic py_sqrt(x::Symbolics.Struct{PyomoVar})
@register_symbolic py_exp(x::Symbolics.Struct{PyomoVar})
@register_symbolic py_log10(x::Symbolics.Struct{PyomoVar})
