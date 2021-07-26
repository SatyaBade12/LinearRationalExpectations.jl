algo = "GS"
endogenous_nbr = 6
exogenous_nbr = 3
exogenous_deterministic_nbr = 0
forward_indices = collect(1:2)
current_indices = collect(1:6)
backward_indices = collect(4:6)
both_indices = Vector{Int64}(undef, 0)
static_indices = [3]

lre_ws = LinearRationalExpectationsWs(algo,
                                  endogenous_nbr,
                                  exogenous_nbr,
                                  exogenous_deterministic_nbr,
                                  forward_indices,
                                  current_indices,
                                  backward_indices,
                                  both_indices,
                                  static_indices)

state_nbr = length(backward_indices)

ws = LinearRationalExpectations.VarianceWs(endogenous_nbr,
                                              state_nbr,
                                              exogenous_nbr,
                                              lre_ws)
nonstate_nbr = endogenous_nbr - state_nbr

for i = 1:100
    nonstationary = true
    while nonstationary
        global A = [zeros(endogenous_nbr, endogenous_nbr - state_nbr) randn(endogenous_nbr, state_nbr)]
        nonstationary = any(abs.(eigen(A[backward_indices, backward_indices]).values) .> 1.0)
    end
    A1 = A[backward_indices, backward_indices]
    A2 = A[lre_ws.non_backward_indices, lre_ws.backward_indices]
    global B = rand(endogenous_nbr, exogenous_nbr)
    B1 = B[backward_indices, :]
    B2 = B[lre_ws.non_backward_indices, :]
    global Σe = randn(exogenous_nbr, exogenous_nbr)
    Σe = transpose(Σe)*Σe
    global Σy = zeros(endogenous_nbr, endogenous_nbr)
    LinearRationalExpectations.compute_variance!(Σy, A1, A2, B1, B2, Σe, ws)
    @test Σy[4:6, 4:6]  ≈ A[4:6, 4:6]*Σy[4:6, 4:6]*transpose(A[4:6, 4:6]) + B[4:6, :]*Σe*transpose(B[4:6, :])
    @test Σy[1:3, 1:3]  ≈ A[1:3, 4:6]*Σy[4:6, 4:6]*transpose(A[1:3, 4:6]) + B[1:3, :]*Σe*transpose(B[1:3, :])
    @test Σy[4:6, 1:3]  ≈ A[4:6, 4:6]*Σy[4:6, 4:6]*transpose(A[1:3, 4:6]) + B[4:6, :]*Σe*transpose(B[1:3, :])
    @test Σy ≈ A*Σy*transpose(A) + B*Σe*transpose(B)
end    

endogenous_nbr = 8
exogenous_nbr = 3

exogenous_deterministic_nbr = 0
forward_indices = collect(1:2)
current_indices = collect(1:8)
backward_indices = collect(4:8)
both_indices = Vector{Int64}(undef, 0)
static_indices = [3]

lre_ws = LinearRationalExpectationsWs(algo,
                                  endogenous_nbr,
                                  exogenous_nbr,
                                  exogenous_deterministic_nbr,
                                  forward_indices,
                                  current_indices,
                                  backward_indices,
                                  both_indices,
                                  static_indices)

state_nbr = length(backward_indices)

ws = LinearRationalExpectations.VarianceWs(endogenous_nbr,
                                              state_nbr,
                                              exogenous_nbr,
                                              lre_ws)
nonstate_nbr = endogenous_nbr - state_nbr

for i = 1:100
    nonstationary = true
    while nonstationary
        A1a = [1 0.5; 0 1]
        A1b = randn(2, 3)
        A2a = randn(3, 3)
        A2b = randn(3, 3)
        global A = hcat(zeros(endogenous_nbr, endogenous_nbr - state_nbr),
                        vcat(hcat(zeros(3, 2),
                                  A2a),
                             hcat(A1a, A1b),
                             hcat(zeros(3, 2),
                                  A2b)))
        nonstationary = any(abs.(eigen(A[backward_indices, backward_indices]).values) .> 1.0)
    end

    A1 = A[backward_indices, backward_indices]
    A2 = A[lre_ws.non_backward_indices, backward_indices]
    global B = rand(endogenous_nbr, exogenous_nbr)

    B1 = B[backward_indices, :]
    B2 = B[lre_ws.non_backward_indices, :]

    global Σe = randn(exogenous_nbr, exogenous_nbr)
    Σe = transpose(Σe)*Σe
    global Σyss = zeros(state_nbr, state_nbr)
    wsl = LinearRationalExpectations.LyapdWs(state_nbr)
    
    LinearRationalExpectations.extended_lyapd!(Σyss, A1, B1*Σe*transpose(B1), wsl)
    global Σy = zeros(endogenous_nbr, endogenous_nbr)
    LinearRationalExpectations.compute_variance!(Σy, A1, A2, B1, B2, Σe, ws)
    global sv = ws.stationary_variables
    sv = [1, 2, 3, 6, 7, 8]
    @test Σy[sv, sv] ≈ A[sv, sv]*Σy[sv, sv]*transpose(A[sv, sv]) + B[sv,:]*Σe*transpose(B[sv, :])
    lre_results = LinearRationalExpectationsResults(endogenous_nbr, exogenous_nbr, state_nbr)
    lre_results.gs1 .= A1
    lre_results.gns1 .= A2
    lre_results.hs1 .= B1
    lre_results.hns1 .= B2
    newΣy = similar(Σy)
    LinearRationalExpectations.compute_variance!(newΣy, lre_results, Σe, ws) 
    @test newΣy[sv, sv] ≈ Σy[sv, sv]

    ws2 = LinearRationalExpectations.VarianceWs(endogenous_nbr,
                                               endogenous_nbr,
                                               exogenous_nbr,
                                               lre_ws)

end    
