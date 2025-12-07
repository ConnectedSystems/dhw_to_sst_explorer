include(joinpath(@__DIR__, "src", "main.jl"))

# Use get_server() for automatic JuliaHub proxy detection
server = Bonito.get_server()
route!(server, "/" => app)

# Display URL
url_to_visit = online_url(server, "/")
@info url_to_visit

# Keep server running
wait(server)
