#!/bin/bash
done="\e[32mdone\e[0m"
failed="\e[31mfailed\e[0m"

echo -n "Start microk8s - ... "; if ! microk8s start &>/dev/null; then echo -e "\rStart microk8s - $failed"; else echo -e "\rStart microk8s - $done"; fi
echo -n "Check microk8s - ... "
if ! microk8s status --wait-ready &>/dev/null; then
  MEM_LIMIT=4000; REAL_MEM=$(free -m | grep 'Mem:' | tr -s " " | cut -d' ' -f2)
  DISK_LIMIT=20000; REAL_DISK=$(df -m / | tail -1 | tr -s ' ' | cut -d' ' -f4)
  if [ "$REAL_MEM" -lt "$MEM_LIMIT" ]; then echo -e "\rAvailable RAM - \e[31mless then 4 Gb\e[0m"; fi
  if [ "$REAL_DISK" -lt "$DISK_LIMIT" ]; then echo -e "\rFree Disk Space - \e[31mless then 20 Gb\e[0m"; fi
  sudo snap install microk8s --classic
  sudo usermod -a -G microk8s "$USER"
  sudo chown -f -R "$USER" "$HOME/.kube"
  echo "Make reboot by command: sudo reboot"; exit 0
else
  echo -e "\rCheck microk8s - $done"
fi

list_addons="$*"; if [ "$list_addons" == "" ]; then list_addons="prometheus fluentd dashboard dns registry ingress"; fi
echo -n "Enable $list_addons - ... "
if ! microk8s enable "$list_addons" &>/dev/null; then
 echo -e "\rEnable $list_addons - $failed"; exit 0
else
 echo -e "\rEnable $list_addons - $done"
fi

echo -e '# Auto-generated please do not edit it\n' > url_token
token_name=$(microk8s kubectl -n kube-system get secret | grep 'default-token' | cut -d' ' -f1)
token=$(microk8s kubectl -n kube-system describe secret "$token_name" | grep 'token:' | tr -s ' ' | cut -d' ' -f2)
echo -e "Dashboard url: \e[34mhttps://$(microk8s kubectl get services -n kube-system | grep 'kubernetes-dashboard' | tr -s ' ' | cut -d' ' -f3)\e[0m" >> url_token
echo -e "Dashboard Token: \033[1m${token}\e[0m" >> url_token
grep -v '#' url_token
