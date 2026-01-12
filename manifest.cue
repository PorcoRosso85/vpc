// vpc manifest (consumer-side substitute for spec-repo inputs)
// Scope: VPC reachability + bindings only (no MCP/JSON-RPC).

package vpc

#NonEmptyString: string & !~"^ *$"
#Path: string & =~"^/"

#Endpoint: {
	method: "GET" | "POST" | "PUT" | "PATCH" | "DELETE"
	path:   #Path
}

#Manifest: close({
	version: "0.1.0"

	requiredBindings: [#NonEmptyString, ...#NonEmptyString]

	opencode: close({
		health: #Endpoint
		doc:    #Endpoint
	})
})

// Concrete normal set (SSOT for this repo).
manifest: #Manifest & {
	requiredBindings: [
		"OPENCODE_SERVICE",
	]

	opencode: {
		health: { method: "GET", path: "/health" }
		doc:    { method: "GET", path: "/openapi.json" }
	}
}
