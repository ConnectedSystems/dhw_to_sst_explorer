include("../src/main.jl")

server = Bonito.get_server()
route!(server, "/" => app)

# Keep server running
wait(server)
