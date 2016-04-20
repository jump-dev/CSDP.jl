# Julia wrapper for header: include/declarations.h
# Automatically generated using Clang.jl wrap_c, version 0.0.0


function triu(A::blockmatrix)
    ccall((:triu,CSDP.csdp),Void,(blockmatrix,),A)
end

function store_packed(A::blockmatrix,B::blockmatrix)
    ccall((:store_packed,CSDP.csdp),Void,(blockmatrix,blockmatrix),A,B)
end

function store_unpacked(A::blockmatrix,B::blockmatrix)
    ccall((:store_unpacked,CSDP.csdp),Void,(blockmatrix,blockmatrix),A,B)
end

function alloc_mat_packed(A::blockmatrix,pB::Ptr{blockmatrix})
    ccall((:alloc_mat_packed,CSDP.csdp),Void,(blockmatrix,Ptr{blockmatrix}),A,pB)
end

function free_mat_packed(A::blockmatrix)
    ccall((:free_mat_packed,CSDP.csdp),Void,(blockmatrix,),A)
end

function structnnz(n::Cint,k::Cint,C::blockmatrix,constraints::Ptr{constraintmatrix})
    ccall((:structnnz,CSDP.csdp),Cint,(Cint,Cint,blockmatrix,Ptr{constraintmatrix}),n,k,C,constraints)
end

function actnnz(n::Cint,lda::Cint,A::Ptr{Cdouble})
    ccall((:actnnz,CSDP.csdp),Cint,(Cint,Cint,Ptr{Cdouble}),n,lda,A)
end

function bandwidth(n::Cint,lda::Cint,A::Ptr{Cdouble})
    ccall((:bandwidth,CSDP.csdp),Cint,(Cint,Cint,Ptr{Cdouble}),n,lda,A)
end

function qreig(n::Cint,maindiag::Ptr{Cdouble},offdiag::Ptr{Cdouble})
    ccall((:qreig,CSDP.csdp),Void,(Cint,Ptr{Cdouble},Ptr{Cdouble}),n,maindiag,offdiag)
end

function sort_entries(k::Cint,C::blockmatrix,constraints::Ptr{constraintmatrix})
    ccall((:sort_entries,CSDP.csdp),Void,(Cint,blockmatrix,Ptr{constraintmatrix}),k,C,constraints)
end

function norm2(n::Cint,x::Ptr{Cdouble})
    ccall((:norm2,CSDP.csdp),Cdouble,(Cint,Ptr{Cdouble}),n,x)
end

function norm1(n::Cint,x::Ptr{Cdouble})
    ccall((:norm1,CSDP.csdp),Cdouble,(Cint,Ptr{Cdouble}),n,x)
end

function norminf(n::Cint,x::Ptr{Cdouble})
    ccall((:norminf,CSDP.csdp),Cdouble,(Cint,Ptr{Cdouble}),n,x)
end

function Fnorm(A::blockmatrix)
    ccall((:Fnorm,CSDP.csdp),Cdouble,(blockmatrix,),A)
end

function Knorm(A::blockmatrix)
    ccall((:Knorm,CSDP.csdp),Cdouble,(blockmatrix,),A)
end

function mat1norm(A::blockmatrix)
    ccall((:mat1norm,CSDP.csdp),Cdouble,(blockmatrix,),A)
end

function matinfnorm(A::blockmatrix)
    ccall((:matinfnorm,CSDP.csdp),Cdouble,(blockmatrix,),A)
end

function calc_pobj(C::blockmatrix,X::blockmatrix,constant_offset::Cdouble)
    ccall((:calc_pobj,CSDP.csdp),Cdouble,(blockmatrix,blockmatrix,Cdouble),C,X,constant_offset)
end

function calc_dobj(k::Cint,a::Ptr{Cdouble},y::Ptr{Cdouble},constant_offset::Cdouble)
    ccall((:calc_dobj,CSDP.csdp),Cdouble,(Cint,Ptr{Cdouble},Ptr{Cdouble},Cdouble),k,a,y,constant_offset)
end

function trace_prod(A::blockmatrix,B::blockmatrix)
    ccall((:trace_prod,CSDP.csdp),Cdouble,(blockmatrix,blockmatrix),A,B)
end

function linesearch(n::Cint,dX::blockmatrix,work1::blockmatrix,work2::blockmatrix,work3::blockmatrix,cholinv::blockmatrix,q::Ptr{Cdouble},z::Ptr{Cdouble},workvec::Ptr{Cdouble},stepfrac::Cdouble,start::Cdouble,printlevel::Cint)
    ccall((:linesearch,CSDP.csdp),Cdouble,(Cint,blockmatrix,blockmatrix,blockmatrix,blockmatrix,blockmatrix,Ptr{Cdouble},Ptr{Cdouble},Ptr{Cdouble},Cdouble,Cdouble,Cint),n,dX,work1,work2,work3,cholinv,q,z,workvec,stepfrac,start,printlevel)
end

function pinfeas(k::Cint,constraints::Ptr{constraintmatrix},X::blockmatrix,a::Ptr{Cdouble},workvec::Ptr{Cdouble})
    ccall((:pinfeas,CSDP.csdp),Cdouble,(Cint,Ptr{constraintmatrix},blockmatrix,Ptr{Cdouble},Ptr{Cdouble}),k,constraints,X,a,workvec)
end

function dinfeas(k::Cint,C::blockmatrix,constraints::Ptr{constraintmatrix},y::Ptr{Cdouble},Z::blockmatrix,work1::blockmatrix)
    ccall((:dinfeas,CSDP.csdp),Cdouble,(Cint,blockmatrix,Ptr{constraintmatrix},Ptr{Cdouble},blockmatrix,blockmatrix),k,C,constraints,y,Z,work1)
end

function dimacserr3(k::Cint,C::blockmatrix,constraints::Ptr{constraintmatrix},y::Ptr{Cdouble},Z::blockmatrix,work1::blockmatrix)
    ccall((:dimacserr3,CSDP.csdp),Cdouble,(Cint,blockmatrix,Ptr{constraintmatrix},Ptr{Cdouble},blockmatrix,blockmatrix),k,C,constraints,y,Z,work1)
end

function op_a(k::Cint,constraints::Ptr{constraintmatrix},X::blockmatrix,result::Ptr{Cdouble})
    ccall((:op_a,CSDP.csdp),Void,(Cint,Ptr{constraintmatrix},blockmatrix,Ptr{Cdouble}),k,constraints,X,result)
end

function op_at(k::Cint,y::Ptr{Cdouble},constraints::Ptr{constraintmatrix},result::blockmatrix)
    ccall((:op_at,CSDP.csdp),Void,(Cint,Ptr{Cdouble},Ptr{constraintmatrix},blockmatrix),k,y,constraints,result)
end

function makefill(k::Cint,C::blockmatrix,constraints::Ptr{constraintmatrix},pfill::Ptr{constraintmatrix},work1::blockmatrix,printlevel::Cint)
    ccall((:makefill,CSDP.csdp),Void,(Cint,blockmatrix,Ptr{constraintmatrix},Ptr{constraintmatrix},blockmatrix,Cint),k,C,constraints,pfill,work1,printlevel)
end

function op_o(k::Cint,constraints::Ptr{constraintmatrix},byblocks::Ptr{Ptr{sparseblock}},Zi::blockmatrix,X::blockmatrix,O::Ptr{Cdouble},work1::blockmatrix,work2::blockmatrix)
    ccall((:op_o,CSDP.csdp),Void,(Cint,Ptr{constraintmatrix},Ptr{Ptr{sparseblock}},blockmatrix,blockmatrix,Ptr{Cdouble},blockmatrix,blockmatrix),k,constraints,byblocks,Zi,X,O,work1,work2)
end

function addscaledmat(A::blockmatrix,scale::Cdouble,B::blockmatrix,C::blockmatrix)
    ccall((:addscaledmat,CSDP.csdp),Void,(blockmatrix,Cdouble,blockmatrix,blockmatrix),A,scale,B,C)
end

function zero_mat(A::blockmatrix)
    ccall((:zero_mat,CSDP.csdp),Void,(blockmatrix,),A)
end

function add_mat(A::blockmatrix,B::blockmatrix)
    ccall((:add_mat,CSDP.csdp),Void,(blockmatrix,blockmatrix),A,B)
end

function sym_mat(A::blockmatrix)
    ccall((:sym_mat,CSDP.csdp),Void,(blockmatrix,),A)
end

function make_i(A::blockmatrix)
    ccall((:make_i,CSDP.csdp),Void,(blockmatrix,),A)
end

function copy_mat(A::blockmatrix,B::blockmatrix)
    ccall((:copy_mat,CSDP.csdp),Void,(blockmatrix,blockmatrix),A,B)
end

function mat_mult(scale1::Cdouble,scale2::Cdouble,A::blockmatrix,B::blockmatrix,C::blockmatrix)
    ccall((:mat_mult,CSDP.csdp),Void,(Cdouble,Cdouble,blockmatrix,blockmatrix,blockmatrix),scale1,scale2,A,B,C)
end

function mat_multspa(scale1::Cdouble,scale2::Cdouble,A::blockmatrix,B::blockmatrix,C::blockmatrix,fill::constraintmatrix)
    ccall((:mat_multspa,CSDP.csdp),Void,(Cdouble,Cdouble,blockmatrix,blockmatrix,blockmatrix,constraintmatrix),scale1,scale2,A,B,C,fill)
end

function mat_multspb(scale1::Cdouble,scale2::Cdouble,A::blockmatrix,B::blockmatrix,C::blockmatrix,fill::constraintmatrix)
    ccall((:mat_multspb,CSDP.csdp),Void,(Cdouble,Cdouble,blockmatrix,blockmatrix,blockmatrix,constraintmatrix),scale1,scale2,A,B,C,fill)
end

function mat_multspc(scale1::Cdouble,scale2::Cdouble,A::blockmatrix,B::blockmatrix,C::blockmatrix,fill::constraintmatrix)
    ccall((:mat_multspc,CSDP.csdp),Void,(Cdouble,Cdouble,blockmatrix,blockmatrix,blockmatrix,constraintmatrix),scale1,scale2,A,B,C,fill)
end

function mat_mult_raw(n::Cint,scale1::Cdouble,scale2::Cdouble,ap::Ptr{Cdouble},bp::Ptr{Cdouble},cp::Ptr{Cdouble})
    ccall((:mat_mult_raw,CSDP.csdp),Void,(Cint,Cdouble,Cdouble,Ptr{Cdouble},Ptr{Cdouble},Ptr{Cdouble}),n,scale1,scale2,ap,bp,cp)
end

function mat_mult_rawatlas(n::Cint,scale1::Cdouble,scale2::Cdouble,ap::Ptr{Cdouble},bp::Ptr{Cdouble},cp::Ptr{Cdouble})
    ccall((:mat_mult_rawatlas,CSDP.csdp),Void,(Cint,Cdouble,Cdouble,Ptr{Cdouble},Ptr{Cdouble},Ptr{Cdouble}),n,scale1,scale2,ap,bp,cp)
end

function matvec(A::blockmatrix,x::Ptr{Cdouble},y::Ptr{Cdouble})
    ccall((:matvec,CSDP.csdp),Void,(blockmatrix,Ptr{Cdouble},Ptr{Cdouble}),A,x,y)
end

function alloc_mat(A::blockmatrix,pB::Ptr{blockmatrix})
    ccall((:alloc_mat,CSDP.csdp),Void,(blockmatrix,Ptr{blockmatrix}),A,pB)
end

function free_mat(A::blockmatrix)
    ccall((:free_mat,CSDP.csdp),Void,(blockmatrix,),A)
end

function initparams(params::Ptr{paramstruc},pprintlevel::Ptr{Cint})
    ccall((:initparams,CSDP.csdp),Void,(Ptr{paramstruc},Ptr{Cint}),params,pprintlevel)
end

function initsoln(n::Cint,k::Cint,C::blockmatrix,a::Ptr{Cdouble},constraints::Ptr{constraintmatrix},pX0::Ptr{blockmatrix},py0::Ptr{Ptr{Cdouble}},pZ0::Ptr{blockmatrix})
    ccall((:initsoln,CSDP.csdp),Void,(Cint,Cint,blockmatrix,Ptr{Cdouble},Ptr{constraintmatrix},Ptr{blockmatrix},Ptr{Ptr{Cdouble}},Ptr{blockmatrix}),n,k,C,a,constraints,pX0,py0,pZ0)
end

function trans(A::blockmatrix)
    ccall((:trans,CSDP.csdp),Void,(blockmatrix,),A)
end

function chol_inv(A::blockmatrix,B::blockmatrix)
    ccall((:chol_inv,CSDP.csdp),Void,(blockmatrix,blockmatrix),A,B)
end

function chol(A::blockmatrix)
    ccall((:chol,CSDP.csdp),Cint,(blockmatrix,),A)
end

function solvesys(m::Cint,ldam::Cint,A::Ptr{Cdouble},rhs::Ptr{Cdouble})
    ccall((:solvesys,CSDP.csdp),Cint,(Cint,Cint,Ptr{Cdouble},Ptr{Cdouble}),m,ldam,A,rhs)
end

function user_exit(n::Cint,k::Cint,C::blockmatrix,a::Ptr{Cdouble},dobj::Cdouble,pobj::Cdouble,constant_offset::Cdouble,constraints::Ptr{constraintmatrix},X::blockmatrix,y::Ptr{Cdouble},Z::blockmatrix,params::paramstruc)
    ccall((:user_exit,CSDP.csdp),Cint,(Cint,Cint,blockmatrix,Ptr{Cdouble},Cdouble,Cdouble,Cdouble,Ptr{constraintmatrix},blockmatrix,Ptr{Cdouble},blockmatrix,paramstruc),n,k,C,a,dobj,pobj,constant_offset,constraints,X,y,Z,params)
end

function read_sol(fname::Ptr{UInt8},n::Cint,k::Cint,C::blockmatrix,pX::Ptr{blockmatrix},py::Ptr{Ptr{Cdouble}},pZ::Ptr{blockmatrix})
    ccall((:read_sol,CSDP.csdp),Cint,(Ptr{UInt8},Cint,Cint,blockmatrix,Ptr{blockmatrix},Ptr{Ptr{Cdouble}},Ptr{blockmatrix}),fname,n,k,C,pX,py,pZ)
end

function read_prob(fname::Ptr{UInt8},pn::Ptr{Cint},pk::Ptr{Cint},pC::Ptr{blockmatrix},pa::Ptr{Ptr{Cdouble}},pconstraints::Ptr{Ptr{constraintmatrix}},printlevel::Cint)
    ccall((:read_prob,CSDP.csdp),Cint,(Ptr{UInt8},Ptr{Cint},Ptr{Cint},Ptr{blockmatrix},Ptr{Ptr{Cdouble}},Ptr{Ptr{constraintmatrix}},Cint),fname,pn,pk,pC,pa,pconstraints,printlevel)
end

function write_prob(fname::ByteString,
                    n::Int,
                    k::Int,
                    C::Blockmatrix,
                    a::Vector{Cdouble},
                    constraints::Vector{constraintmatrix})
    ccall((:write_prob,CSDP.csdp),Cint,(Ptr{UInt8},Cint,Cint,blockmatrix,Ptr{Cdouble},Ptr{constraintmatrix}),
          fname,n,k,C,fptr(a),fptr(constraints))
end

function write_sol(fname::ByteString,
                   n::Int,
                   k::Int,
                   X::blockmatrix,
                   y::Ptr{Cdouble},
                   Z::blockmatrix)
    ccall((:write_sol,CSDP.csdp),Cint,
          (Ptr{UInt8},
           Cint,
           Cint,
           blockmatrix,
           Ptr{Cdouble},
           blockmatrix),fname,n,k,X,y,Z)
end

function write_sol(fname::ByteString,
                   n::Int,
                   k::Int,
                   X::Blockmatrix,
                   y::Cvector{Cdouble},
                   Z::Blockmatrix)
    ccall((:write_sol,CSDP.csdp),Cint,
          (Ptr{UInt8},
           Cint,
           Cint,
           blockmatrix,
           Ptr{Cdouble},
           blockmatrix),fname,n,k,X,y.e,Z)
end


function free_prob(n::Cint,k::Cint,C::blockmatrix,a::Ptr{Cdouble},constraints::Ptr{constraintmatrix},X::blockmatrix,y::Ptr{Cdouble},Z::blockmatrix)
    ccall((:free_prob,CSDP.csdp),Void,(Cint,Cint,blockmatrix,Ptr{Cdouble},Ptr{constraintmatrix},blockmatrix,Ptr{Cdouble},blockmatrix),n,k,C,a,constraints,X,y,Z)
end

function sdp(n::Cint,k::Cint,C::blockmatrix,a::Ptr{Cdouble},constant_offset::Cdouble,constraints::Ptr{constraintmatrix},byblocks::Ptr{Ptr{sparseblock}},fill::constraintmatrix,X::blockmatrix,y::Ptr{Cdouble},Z::blockmatrix,cholxinv::blockmatrix,cholzinv::blockmatrix,pobj::Ptr{Cdouble},dobj::Ptr{Cdouble},work1::blockmatrix,work2::blockmatrix,work3::blockmatrix,workvec1::Ptr{Cdouble},workvec2::Ptr{Cdouble},workvec3::Ptr{Cdouble},workvec4::Ptr{Cdouble},workvec5::Ptr{Cdouble},workvec6::Ptr{Cdouble},workvec7::Ptr{Cdouble},workvec8::Ptr{Cdouble},diagO::Ptr{Cdouble},bestx::blockmatrix,besty::Ptr{Cdouble},bestz::blockmatrix,Zi::blockmatrix,O::Ptr{Cdouble},rhs::Ptr{Cdouble},dZ::blockmatrix,dX::blockmatrix,dy::Ptr{Cdouble},dy1::Ptr{Cdouble},Fp::Ptr{Cdouble},printlevel::Cint,parameters::paramstruc)
    ccall((:sdp,CSDP.csdp),Cint,(Cint,Cint,blockmatrix,Ptr{Cdouble},Cdouble,Ptr{constraintmatrix},Ptr{Ptr{sparseblock}},constraintmatrix,blockmatrix,Ptr{Cdouble},blockmatrix,blockmatrix,blockmatrix,Ptr{Cdouble},Ptr{Cdouble},blockmatrix,blockmatrix,blockmatrix,Ptr{Cdouble},Ptr{Cdouble},Ptr{Cdouble},Ptr{Cdouble},Ptr{Cdouble},Ptr{Cdouble},Ptr{Cdouble},Ptr{Cdouble},Ptr{Cdouble},blockmatrix,Ptr{Cdouble},blockmatrix,blockmatrix,Ptr{Cdouble},Ptr{Cdouble},blockmatrix,blockmatrix,Ptr{Cdouble},Ptr{Cdouble},Ptr{Cdouble},Cint,paramstruc),n,k,C,a,constant_offset,constraints,byblocks,fill,X,y,Z,cholxinv,cholzinv,pobj,dobj,work1,work2,work3,workvec1,workvec2,workvec3,workvec4,workvec5,workvec6,workvec7,workvec8,diagO,bestx,besty,bestz,Zi,O,rhs,dZ,dX,dy,dy1,Fp,printlevel,parameters)
end

function easy_sdp(n::Cint,k::Cint,C::blockmatrix,a::Ptr{Cdouble},constraints::Ptr{constraintmatrix},constant_offset::Cdouble,pX::Ptr{blockmatrix},py::Ptr{Ptr{Cdouble}},pZ::Ptr{blockmatrix},ppobj::Ptr{Cdouble},pdobj::Ptr{Cdouble})
    ccall((:easy_sdp,CSDP.csdp),Cint,(Cint,Cint,blockmatrix,Ptr{Cdouble},Ptr{constraintmatrix},Cdouble,Ptr{blockmatrix},Ptr{Ptr{Cdouble}},Ptr{blockmatrix},Ptr{Cdouble},Ptr{Cdouble}),n,k,C,a,constraints,constant_offset,pX,py,pZ,ppobj,pdobj)
end

function tweakgap(n::Cint,k::Cint,a::Ptr{Cdouble},constraints::Ptr{constraintmatrix},gap::Cdouble,Z::blockmatrix,dZ::blockmatrix,y::Ptr{Cdouble},dy::Ptr{Cdouble},work1::blockmatrix,work2::blockmatrix,work3::blockmatrix,work4::blockmatrix,workvec1::Ptr{Cdouble},workvec2::Ptr{Cdouble},workvec3::Ptr{Cdouble},workvec4::Ptr{Cdouble},printlevel::Cint)
    ccall((:tweakgap,CSDP.csdp),Void,(Cint,Cint,Ptr{Cdouble},Ptr{constraintmatrix},Cdouble,blockmatrix,blockmatrix,Ptr{Cdouble},Ptr{Cdouble},blockmatrix,blockmatrix,blockmatrix,blockmatrix,Ptr{Cdouble},Ptr{Cdouble},Ptr{Cdouble},Ptr{Cdouble},Cint),n,k,a,constraints,gap,Z,dZ,y,dy,work1,work2,work3,work4,workvec1,workvec2,workvec3,workvec4,printlevel)
end

function bisect_(n::Ptr{Cint},eps1::Ptr{Cdouble},d::Ptr{Cdouble},e::Ptr{Cdouble},e2::Ptr{Cdouble},lb::Ptr{Cdouble},ub::Ptr{Cdouble},mm::Ptr{Cint},m::Ptr{Cint},w::Ptr{Cdouble},ind::Ptr{Cint},ierr::Ptr{Cint},rv4::Ptr{Cdouble},rv5::Ptr{Cdouble})
    ccall((:bisect_,CSDP.csdp),Cint,(Ptr{Cint},Ptr{Cdouble},Ptr{Cdouble},Ptr{Cdouble},Ptr{Cdouble},Ptr{Cdouble},Ptr{Cdouble},Ptr{Cint},Ptr{Cint},Ptr{Cdouble},Ptr{Cint},Ptr{Cint},Ptr{Cdouble},Ptr{Cdouble}),n,eps1,d,e,e2,lb,ub,mm,m,w,ind,ierr,rv4,rv5)
end
