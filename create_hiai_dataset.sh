#!/bin/bash

set -x

DATASET="${PWD##*/}"
ANNOTATIONS_DIR="${PWD}/HiAIAnnotations"
IMAGES_DIR="${DATASET}Raw"
IMAGES_DIR_PATH="${PWD}/${IMAGES_DIR}"

function create_labels 
{
  mkdir -p "${ANNOTATIONS_DIR}"
  LABEL_FILE="${ANNOTATIONS_DIR}/HiAI_label.json"
  echo -n '{' >  "${LABEL_FILE}"
  for n in `ls data` ; do
    for class in `ls data/$n` ; do
      echo -n '"'${n}'": "'${class}'", ' >> "${LABEL_FILE}"
    done
  done
  sed -i 's/,\s$/}/' "${LABEL_FILE}"
}

function create_annotation
{
  local file="$1"
  local width="$2"
  local category_id="$3"
  local category_name="$4"
  local id="$5"
  local height="$6"
  
  cat <<EOF > "${ANNOTATIONS_DIR}/${file%.*}.json"
{
  "image":{
    "folder":"${IMAGES_DIR_PATH}",
    "file_name":"${file}",
    "width":${width},
    "annotations":[
    {
      "isCrowd":0,
      "category_name":"${category_name}",
      "category_id":"${category_id}",
      "bbox":[],
      "segmentation":{}
    }],
    "id":${id},
    "height":${height}
  },
  "type":"${DATASET}",
  "info":{
    "contributor":"AxxonSoft",
    "date_created":"",
    "description":""
  }
}  
EOF
}

function make_dataset
{
  create_labels
  
  local DATA_INFO=".${DATASET}_data.info"
  cat <<EOF > "${DATA_INFO}"
${DATASET} $(ls ${IMAGES_DIR_PATH} | wc -l) -1.0 -1.0 -1.0
-1 0
0 0
1 $(ls ${IMAGES_DIR_PATH} | wc -l)
EOF
  
  local id=0
  mkdir -p "${IMAGES_DIR_PATH}"
  for n in `ls data` ; do
    class="`ls data/$n`"
    class_dir="data/${n}/${class}"
    for file in `ls ${class_dir}` ; do
      result_file="${file%%.*}_${class}.${file##*.}"
      cp "${class_dir}/${file}" "${IMAGES_DIR_PATH}/${result_file}"
      create_annotation "${result_file}" 224 ${n} ${class} ${id} 224
      echo "${id} ${IMAGES_DIR}/${result_file} 224 224 `stat ${IMAGES_DIR_PATH}/${result_file} -c %s`" >> "${DATA_INFO}"
      (( id++ ))
    done
  done

  cat <<EOF >> "${DATA_INFO}"
2 0
3 0
4 0
EOF
}

make_dataset
