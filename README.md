# Differential OpenShift Operator Bundles 

This is a collection of proof-of-concept scripts for managing OpenShift operator bundles for offline/disconnected networks. 

## Workflow

Notice: This is pseudo code for the demonstration of the workflow.

These Resources would be used in the following order

1. Create the Initial bundle:
```
./container-launch.sh 
./bundle.sh '<< Red Hat Pull Secret >>

```
Note: This container now contains information used for differential container image bundling. We will return to it to create subsequent differential bundles.

The previous command will produce a compressed tar with some example operators in v2 registry format in the directory that it was launched from.

2. Transfer bundle to disconnected network.

Note: The disconnected host that contains the bundle will need:
- skopeo
- podman
- quay.io/redhatgov/compliance-disconnected:latest 
- registry:2

3. Extract the archive and get in there:
```
tar xzvf operator-bundle-1.tar.gz && \
cd bundle
```

4. Launch the execution environment:
`./scripts/install-container-launch.sh`

5. Start docker registry in execution env with something like:
```
  podman run -d \
  -p 5000:5000 \
  --name registry \
  -v ./bundle/operators:/var/lib/registry \
  registry:2
```

6. Upload bundle to target disconnected registry. In execution env run upload.sh

7. From internet connected machine. From previously running container add an operator to the `offline-operator-list`

8. Run bundler again:
`./bundle.sh '<< RH pull secret>>'`

9. Transfer bundle to disconnected network. Should be labeled `operator-bundle-2.tar.gz`

10. From the execution environment, run `./diff-update.sh operator-bundle-2.tar.gz` 

11. Then mirror to the target disconnected registry `./upload.sh`




