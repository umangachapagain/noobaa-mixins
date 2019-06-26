#!/bin/sh

set +ex

deploy() {
        oc label ns $1 openshift.io/cluster-monitoring=true || true
        cat <<EOF | oc create -f -
kind: Role
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: noobaa-metrics
  namespace: $1
rules:
 - apiGroups:
   - ""
   resources:
    - services
    - endpoints
    - pods
   verbs:
    - get
    - list
    - watch
---
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: noobaa-metrics
  namespace: $1
rules:
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: noobaa-metrics
subjects:
- kind: ServiceAccount
  name: prometheus-k8s
  namespace: openshift-monitoring
---
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  labels:
    app: noobaa
  name: noobaa-mgr
  namespace: $1
spec:
  namespaceSelector:
    matchNames:
      - $1
  endpoints:
    - interval: 30s
      port: mgmt
      path: /metrics
  selector:
    matchLabels:
      app: noobaa
EOF
}

clean() {
        oc label ns $1 openshift.io/cluster-monitoring-
        oc delete servicemonitor noobaa-mgr -n $1
        oc delete role noobaa-metrics -n $1
        oc delete rolebinding noobaa-metrics -n $1
}

if [ $1 == deploy ]
then
        if [ $2 != "" ]
        then
                deploy $2
        fi
elif [ $1 == clean ]
then
        if [ $2 != "" ]
        then
                clean $2
        fi
else
        echo -e "deploy - to enable monitoring \nclean - to cleanup monitoring"
fi
