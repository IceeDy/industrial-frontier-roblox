--!strict
return {
	RequestSnapshot = { className = "RemoteFunction", direction = "client_to_server", ratePerSecond = 2 },
	SubmitAction = { className = "RemoteEvent", direction = "client_to_server", ratePerSecond = 5 },
	SnapshotUpdated = { className = "RemoteEvent", direction = "server_to_client", ratePerSecond = 10 },
}
