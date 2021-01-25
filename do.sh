function timestamp() {
    awk '{print "\033[32m", strftime("%Y-%m-%dT%H:%M:%S"), "\033[0m", $0}'
}

function docker-build-at-host {
    git push
    ssh ${1:?host to build at} 'git clone '$(git remote get-url origin)' tmp-build; cd tmp-build; git pull origin master; make push'
}

function bump() {
    level=${1:-patch}
    bump2version  $level --verbose --commit --tag
    bump2version  release --verbose --commit --tag
}

function upload() {
    python setup.py sdist bdist_wheel
    twine upload $(ls -tr dist/*gz | tail -1) || true
    twine upload $(ls -tr dist/*whl | tail -1) || true
}

function k8s-clean-evicted() {
    kubectl get po --all-namespaces -o json | jq  '.items[] | select(.status.reason!=null) | select(.status.reason | contains("Evicted")) | "kubectl delete po \(.metadata.name) -n \(.metadata.namespace)"' | xargs -n 1 bash -c
}

function prep {
    module=${1:?}
    targs=${2:-}
    pylint -E $module && echo "linted" && mypy $module && python -m pytest tests/ --maxfail=1 ${targs}
}

function color {
    awk '
    $0~/'$1'/ {print "\033[31m",$0,"\033[0m"; m=1}
    "'$2'"!="" && $0~/'$2'/ {print "\033[32m",$0,"\033[0m"; m=1}
    m != 1 {print}

    '
}

function evicted-clean() {
    kubectl get po  --all-namespaces -o json | jq  '.items[] | select(.status.reason!=null) | select(.status.reason | contains("Evicted")) | "kubectl delete po \(.metadata.name) -n \(.metadata.namespace)"' | xargs -n 1 bash -c
}

$@
