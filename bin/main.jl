include(joinpath(@__DIR__, "src", "main.jl"))

# Use get_server() for automatic JuliaHub proxy detection
server = Bonito.get_server()
route!(server, "/" => app)

# Keep server running
wait(server)
