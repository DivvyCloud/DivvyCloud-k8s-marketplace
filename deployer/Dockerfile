FROM launcher.gcr.io/google/debian9 AS build
RUN apt-get update \
    && apt-get install -y --no-install-recommends gettext
ADD k8s-helm-chart/divvycloud /tmp/chart
RUN ( cd /tmp && tar -czvf /tmp/divvycloud.tar.gz chart)

ADD apptest/deployer/divvycloud /tmp/test/chart
RUN ( cd /tmp/test && tar -czvf /tmp/test/divvycloud.tar.gz chart)

ADD schema.yaml /tmp/schema.yaml
ADD apptest/deployer/schema.yaml /tmp/schema-test.yaml

ARG REGISTRY
ARG TAG
RUN cat /tmp/schema.yaml | env -i "REGISTRY=$REGISTRY" "TAG=$TAG" envsubst > /tmp/schema.yaml.new && mv /tmp/schema.yaml.new /tmp/schema.yaml

FROM gcr.io/cloud-marketplace-tools/k8s/deployer_helm
COPY --from=build /tmp/divvycloud.tar.gz /data/chart
COPY --from=build /tmp/schema.yaml /data/

COPY --from=build /tmp/test/divvycloud.tar.gz /data-test/chart
COPY --from=build /tmp/schema-test.yaml /data-test/schema.yaml

