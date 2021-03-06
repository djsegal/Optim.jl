function OnceDifferentiable(f, x_seed::AbstractArray{T}, F = zero(T); autodiff = :finite) where T
    if autodiff == :finite
        function g!(storage, x)
            Calculus.finite_difference!(f, x, storage, :central)
            return
        end
        function fg!(storage, x)
            g!(storage, x)
            return f(x)
        end
    elseif autodiff == :forward
        gcfg = ForwardDiff.GradientConfig(f, x_seed)
        g! = (out, x) -> ForwardDiff.gradient!(out, f, x, gcfg)

        fg! = (out, x) -> begin
            gr_res = DiffBase.DiffResult(zero(T), out)
            ForwardDiff.gradient!(gr_res, f, x, gcfg)
            DiffBase.value(gr_res)
        end
    else
        error("The autodiff value $autodiff is not support. Use :finite or :forward.")
    end
    OnceDifferentiable(f, g!, fg!, x_seed)
end

function TwiceDifferentiable(f, g!, x_seed::AbstractVector{T}, F = zero(T); autodiff = :finite) where T
    n_x = length(x_seed)
    function fg!(storage, x)
        g!(storage, x)
        return f(x)
    end
    if autodiff == :finite
        function h!(storage, x)
            Calculus.finite_difference_hessian!(f, x, storage)
            return
        end
    elseif autodiff == :forward
        hcfg = ForwardDiff.HessianConfig(similar(x_seed))
        h! = (out, x) -> ForwardDiff.hessian!(out, f, x, hcfg)
    else
        error("The autodiff value $(autodiff) is not supported. Use :finite or :forward.")
    end
    TwiceDifferentiable(f, g!, fg!, h!, x_seed, F)
end

TwiceDifferentiable(d::NonDifferentiable, x_seed::AbstractVector{T} = d.x_f, F = zero(T); autodiff = :finite) where {T<:Real} =
    TwiceDifferentiable(d.f, x_seed, F; autodiff = autodiff)

function TwiceDifferentiable(d::OnceDifferentiable, x_seed::AbstractVector{T} = d.x_f, F = zero(T); autodiff = :finite) where T<:Real
    if autodiff == :finite
        function h!(storage, x)
            Calculus.finite_difference_hessian!(d.f, x, storage)
            return
        end
    elseif autodiff == :forward
        hcfg = ForwardDiff.HessianConfig(similar(gradient(d)))
        h! = (out, x) -> ForwardDiff.hessian!(out, d.f, x, hcfg)
    else
        error("The autodiff value $(autodiff) is not supported. Use :finite or :forward.")
    end
    return TwiceDifferentiable(d.f, d.df, d.fdf, h!, x_seed, F, gradient(d))
end
    
function TwiceDifferentiable(f, x::AbstractVector{T}, F = zero(T); autodiff = :finite) where T
    if autodiff == :finite
        function g!(storage::Vector, x::Vector)
            Calculus.finite_difference!(f, x, storage, :central)
            return
        end
        function fg!(storage::Vector, x::Vector)
            g!(storage, x)
            return f(x)
        end
        function h!(storage::Matrix, x::Vector)
            Calculus.finite_difference_hessian!(f, x, storage)
            return
        end
    elseif autodiff == :forward
        gcfg = ForwardDiff.GradientConfig(f, x)
        g! = (out, x) -> ForwardDiff.gradient!(out, f, x, gcfg)

        fg! = (out, x) -> begin
            gr_res = DiffBase.DiffResult(zero(T), out)
            ForwardDiff.gradient!(gr_res, f, x, gcfg)
            DiffBase.value(gr_res)
        end

        hcfg = ForwardDiff.HessianConfig(f, x)
        h! = (out, x) -> ForwardDiff.hessian!(out, f, x, hcfg)
    else
        error("The autodiff value $(autodiff) is not supported. Use :finite or :forward.")
    end
    TwiceDifferentiable(f, g!, fg!, h!, x, F)
end
