local kf                = import "kfctl.libsonnet";
local utils             = import "utils.libsonnet";

local istio = [
  kf.KustomizeConfig("istio/cluster-local-gateway", parameters={"namespace": "istio-system"}),
  kf.KustomizeConfig("istio/kfserving-gateway", parameters={"namespace": "istio-system"}),
  kf.KustomizeConfig("istio/istio", overlays=["agilestacks"], parameters={"clusterRbacConfig": "OFF"}),
  kf.KustomizeConfig("istio/oidc-authservice", overlays=["application", "agilestacks"],
    parameters={
      "client_id":          std.extVar("HUB_OIDC_CLIENT_ID"),
      "oidc_provider":      std.extVar("HUB_OIDC_AUTH_URI"),
      "oidc_redirect_uri":  std.extVar("HUB_OIDC_REDIRECT_URI"),
      "oidc_auth_url":      std.extVar("HUB_OIDC_AUTH_URI") + "/auth",
      "application_secret": std.extVar("HUB_OIDC_SECRET"),
      "skip_auth_uri":      std.extVar("HUB_OIDC_AUTH_URI"),
      "userid-header":      "kubeflow-userid",
      "namespace":          "istio-system"
    }),
  kf.KustomizeConfig("istio/add-anonymous-user-filter", overlays=["agilestacks"]),
];

local installCertManager = false;
local certManager = if installCertManager then [
  kf.KustomizeConfig("cert-manager/cert-manager-crds", 
    parameters={"namespace": "cert-manager"}),
  kf.KustomizeConfig("cert-manager/cert-manager-kube-system-resources", 
    parameters={"namespace": "kube-system"}),
  kf.KustomizeConfig("cert-manager/cert-manager", 
    overlays=["self-signed", "application"], 
    parameters={"namespace": "cert-manager"}),
] else [];

local metacontroller = [
  kf.KustomizeConfig("application/application-crds"),
  kf.KustomizeConfig("application/application", overlays=["application"],),
  kf.KustomizeConfig("metacontroller"),
];

local argo = [
  kf.KustomizeConfig("argo", overlays = ["istio", "application", "agilestacks"])
];

local centraldashboard = [
  kf.KustomizeConfig("common/centraldashboard", 
    overlays=["istio", "application"],
    parameters={
      "userid-header": "kubeflow-userid",
      "namespace":     std.extVar("HUB_COMPONENT_NAMESPACE")
    }),
];

local metadata = [
  kf.KustomizeConfig("metadata", overlays=["istio", "db", "application"]),
];

local spark = [
  kf.KustomizeConfig("spark/spark-operator", overlays=["application"]),
];

local pytorch = [
  kf.KustomizeConfig("pytorch-job/pytorch-job-crds", overlays=["application"]),
  kf.KustomizeConfig("pytorch-job/pytorch-operator", overlays=["application"]),
];

local kfserving = [
  kf.KustomizeConfig("knative/knative-serving-crds", 
    overlays=["application"], 
    parameters={"namespace": "knative-serving"}),
  kf.KustomizeConfig("knative/knative-serving-install", 
    overlays=["application","agilestacks"], 
    parameters={"namespace": "knative-serving"}),
  kf.KustomizeConfig("kfserving/kfserving-crds", overlays=["application"]),
  kf.KustomizeConfig("kfserving/kfserving-install", overlays=["application"]),
];

// local spartakus = [
//   kf.KustomizeConfig("common/spartakus", overlays=["application"],
//     parameters=[
//       kf.NameValue("usageId", std.md5(name)),
//       kf.NameValue("reportUsage", "false")
//     ],),
// ];

local jupyter = [
  kf.KustomizeConfig("jupyter/jupyter-web-app", 
    overlays=["istio", "application"],
    parameters={"userid-header": "kubeflow-userid"}),  
  kf.KustomizeConfig("jupyter/notebook-controller", overlays=["istio", "application"]),
];

local tensorboard = [
  kf.KustomizeConfig("tensorboard", overlays=["istio"]),
  kf.KustomizeConfig("tf-training/tf-job-crds", overlays=["application"]),
  kf.KustomizeConfig("tf-training/tf-job-operator", overlays=["application"]),
];

local katib = [
  kf.KustomizeConfig("katib/katib-crds", overlays=["application"]),
  kf.KustomizeConfig("katib/katib-controller", overlays=["istio", "application"]),
];

local minio = [
  kf.KustomizeConfig("pipeline/minio", overlays=["application"],
  parameters={
    "minioPvcName": "kf-"+std.extVar("HUB_COMPONENT")+"-minio"
  }),
];

local mysql = [
  kf.KustomizeConfig( "pipeline/mysql", 
    overlays=["application"],
    parameters={
      mysqlPvcName: std.extVar("HUB_COMPONENT") + "-minio"
    }),
];

local s3url = utils.parse_url(std.extVar("HUB_S3_ENDPOINT"));
local pipeline = [
  kf.KustomizeConfig("pipeline/api-service", 
    overlays=["application", "agilestacks"],
    parameters={
      mysqlHost:      std.extVar("HUB_MYSQL_HOST"),
      mysqlUser:      std.extVar("HUB_MYSQL_DB_USER"),
      mysqlPassword:  std.extVar("HUB_MYSQL_DB_PASS"),
      mysqlDatabase:  std.extVar("HUB_MYSQL_DB_NAME"),
      s3AccessKey:    std.extVar("HUB_S3_ACCESS_KEY"),
      s3SecretKey:    std.extVar("HUB_S3_SECRET_KEY"),
      s3BucketName:   std.extVar("HUB_S3_BUCKET"),
      s3Region:       std.extVar("HUB_S3_REGION"),
      s3EndpointHost: s3url.host,
      s3EndpointPort: s3url.port,
    }),
  kf.KustomizeConfig("pipeline/pipelines-runner", overlays=["application"]),
  kf.KustomizeConfig("pipeline/pipelines-ui", overlays=["istio", "application"]),
  kf.KustomizeConfig("pipeline/scheduledworkflow", overlays=["application"]),
  kf.KustomizeConfig("pipeline/pipeline-visualization-service", overlays=["application"]),
];

local seldon = [
  kf.KustomizeConfig("seldon/seldon-core-operator", overlays=["application"]),
];

local admissionWebHook = if installCertManager then [
  kf.KustomizeConfig("admission-webhook/webhook", overlays=["cert-manager", "application"]),
] else [
  kf.KustomizeConfig("admission-webhook/bootstrap", overlays=["application"]),
  kf.KustomizeConfig("admission-webhook/webhook", overlays=["application"]),
];

local profile = [
  kf.KustomizeConfig("profiles", overlays=["application", "istio", "agilestacks"],
    parameters={
      "userid-header": "kubeflow-userid",
      "admin": std.extVar("HUB_DEX_USER"),
    }
  )
];

kf.Definition(
  name=std.extVar("HUB_COMPONENT"), 
  namespace=std.extVar("HUB_COMPONENT_NAMESPACE")) {
  spec+: {
    applications+: []
      + metacontroller
      + istio 
      + certManager
      // + dex
      + argo 
      + admissionWebHook
      + centraldashboard
      // + spark 
      + metadata
      + jupyter
      + pytorch
      + kfserving
      // + spartakus
      + tensorboard
      + katib
      // + minio
      // + mysql
      + pipeline
      + seldon
      + profile
    repos: [kf.Repo("manifests", std.extVar("KF_REPO"))],
    version: std.extVar("HUB_COMPONENT_VERSION"),
  },
  metadata+: {
    clusterName: std.extVar("HUB_DOMAIN_NAME"),
  }
}
