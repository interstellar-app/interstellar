#!/bin/sh

# Copied from https://github.com/thunder-app/thunder/blob/develop/.github/workflows/instances.yml

curl -H 'Content-Type: application/json' -X POST -d '{"query": "query {nodes(softwarename: \"lemmy\") {domain}}"}' https://api.fediverse.observer 2> /dev/null | jq -r '.data.nodes | .[] | .domain' | sort | uniq -i > lemmy_instances.txt
curl -H 'Content-Type: application/json' -X POST -d '{"query": "query {nodes(softwarename: \"piefed\") {domain}}"}' https://api.fediverse.observer 2> /dev/null | jq -r '.data.nodes | .[] | .domain' | sort | uniq -i > piefed_instances.txt
curl -H 'Content-Type: application/json' -X POST -d '{"query": "query {nodes(softwarename: \"mbin\") {domain}}"}' https://api.fediverse.observer 2> /dev/null | jq -r '.data.nodes | .[] | .domain' | sort | uniq -i > mbin_instances.txt

# Theres a lot more mastodon instances so only include those with certain active user count.
#curl -H 'Content-Type: application/json' -X POST -d '{"query": "query {nodes(softwarename: \"mastodon\") {domain active_users_monthly}}"}' https://api.fediverse.observer 2> /dev/null | jq -r '.data.nodes | .[] | select(.active_users_monthly > 100) | .domain' | sort | uniq -i > mastodon_instances.txt

cat lemmy_instances.txt piefed_instances.txt mbin_instances.txt | sort | uniq -i > instances.txt

cat << EOF > lib/src/utils/instances.dart
import 'package:interstellar/src/controller/server.dart';
const Map<String, ServerSoftware> knownInstances = {
$(awk '{ print "  \047"$0"\047: ServerSoftware.mbin," }' mbin_instances.txt)

$(awk '{ print "  \047"$0"\047: ServerSoftware.piefed," }' piefed_instances.txt)

$(awk '{ print "  \047"$0"\047: ServerSoftware.lemmy," }' lemmy_instances.txt)
};
EOF

# Put the instances in the Android manifest file
manifestInstances="$(awk '{ print "                <data android:host=\""$0"\" />" }' instances.txt)"
inSection=false
while IFS= read -r line; do
    if [[ $line == *"#AUTO_GEN_INSTANCE_LIST_DO_NOT_TOUCH#"* ]]; then
      inSection=true
    fi

    if [[ $line == *"#INSTANCE_LIST_END#"* ]]; then
      echo "$manifestInstances" >> android/app/src/main/AndroidManifest-new.xml
      inSection=false
    fi

    if [[ $line == *"android:host"* ]]; then
      if [ "$inSection" = true ]; then
        continue
      fi
    fi

    echo "$line" >> android/app/src/main/AndroidManifest-new.xml
done < android/app/src/main/AndroidManifest.xml
mv android/app/src/main/AndroidManifest-new.xml android/app/src/main/AndroidManifest.xml

rm instances.txt lemmy_instances.txt piefed_instances.txt mbin_instances.txt