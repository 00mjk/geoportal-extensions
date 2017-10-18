#!/bin/bash

# FIXME
# authentification github pour 'git push' via SSH ou Token
# https://help.github.com/articles/connecting-to-github-with-ssh/
#   https://help.github.com/articles/which-remote-url-should-i-use/#cloning-with-ssh-urls
#   https://docs.microsoft.com/en-us/vsts/git/use-ssh-keys-to-authenticate
#   https://developer.github.com/v3/guides/basics-of-authentication/ && https://developer.github.com/v3/guides/managing-deploy-keys/
# https://help.github.com/articles/git-automation-with-oauth-tokens/

# FIXME
# authentification npm pour 'npm publish'
# idem avec bower...

# TODO
# impl. les options longues
# Ex. --leaflet

# set -x

# répertoire d'execution
_PWD=`pwd`

# version du shell
_VERSION=0.0.1

# librairie par defaut
_LIBRARY="leaflet"

# options
#   -leaflet
#   (-debug )
#   -no-build |b, -no-data |d, -no-json |j, -no-info |i, -no-commit |o, -no-publish |p, -no-clean |c
_OPTS_RUN_BUILD=false
_OPTS_RUN_DATA=false
_OPTS_RUN_JSON=false
_OPTS_RUN_INFO=false
_OPTS_RUN_COMMIT=false
_OPTS_RUN_PUBLISH=false
_OPTS_RUN_CLEAN=false

# parse options
while getopts "lhbdjicpC" opt; do
  case ${opt} in
    h|help )
      echo "Usage :"
      echo "    `basename $0` -h    Affiche cette aide."
      echo "    l (--leaflet)     Execution de la publication Leaflet (par defaut),"
      echo "    o (--ol3)         Execution de la publication Openlayers,"
      echo "    b (--run-build)   Execution de la tache de compilation,"
      echo "    d (--run-data)    Execution de la tache de git-clone,"
      echo "    j (--run-json)    Execution de la tache de creation des json,"
      echo "    i (--run-info)    Execution de la tache de creation du fichier d'info,"
      echo "    c (--run-commit)  Execution de la tache de git-push,"
      echo "    p (--run-publish) Execution de la tache de publication npm et bower,"
      echo "    C (--run-clean)   Execution de la tache de nettoyage."
      echo "Ex. `basename $0` -bdjicpC"
      exit 0
      ;;
   \? )
     echo "Invalid Option: -$OPTARG" 1>&2
     exit 1
     ;;
   l|leaflet )
      _LIBRARY="leaflet"
      GIT_DIR_PUBLISH=${_GIT_DIR_PUBLISH_LEAFLET}
      GIT_REPOSITORY=${_GIT_REPOSITORY_LEAFLET}
     ;;
   o|ol3 )
      _LIBRARY="ol3"
     ;;
   b|build )
      _OPTS_RUN_BUILD=true
     ;;
   d|data )
      _OPTS_RUN_DATA=true
     ;;
   j|json )
      _OPTS_RUN_JSON=true
     ;;
   i|info )
      _OPTS_RUN_INFO=true
     ;;
   c|commit )
     _OPTS_RUN_COMMIT=true
     ;;
   p|publish )
      _OPTS_RUN_PUBLISH=true
     ;;
   C|clean )
      _OPTS_RUN_CLEAN=true
     ;;
  esac
  shift $((OPTIND -1))
done

# chemins des répertoires
_DIR_SCRIPTS="${_PWD}/scripts"
_DIR_SRC="${_PWD}/src"
_DIR_DIST="${_PWD}/dist"

# chargement des properties
_PROPERTIES="${_DIR_SCRIPTS}/release.ini"
source ${_PROPERTIES}

# git
GIT_COMMIT_MESSAGE=${_GIT_COMMIT_MESSAGE}
GIT_FILES_ADD=${_GIT_FILES_ADD}
GIT_USERNAME=${_GIT_USERNAME}
GIT_TOKEN=${_GIT_TOKEN}

[ ${_LIBRARY} == "leaflet" ] && {
  GIT_DIR_PUBLISH=${_GIT_DIR_PUBLISH_LEAFLET}
  GIT_REPOSITORY="https://github.com/${GIT_USERNAME}/${_GIT_NAME_REPOSITORY_LEAFLET}.git"
}

[ ${_LIBRARY} == "ol3" ] && {
  GIT_DIR_PUBLISH=${_GIT_DIR_PUBLISH_OPENLAYERS}
  GIT_REPOSITORY="https://github.com/${GIT_USERNAME}/${_GIT_NAME_REPOSITORY_OPENLAYERS}.git"
}

##########
# doCmd()

doCmd () {
    cmd2issue=$1
    eval ${cmd2issue}
    retour=$?
    if [ $retour -ne 0 ] ; then
        printTo "Erreur d'execution (code:${retour}) !..."
        exit 100
    fi
}

##########
# printTo()

printTo () {
    text=$1
    d=`date`
    echo "[${d}] ${text}"
}

##########
# info()

info () {
    cat >&2 <<EOF

----------------------------------------------------------
`basename $0`, version ${_VERSION}
----------------------------------------------------------
--> Publication des releases ${_LIBRARY} <--
-- Configuration : ${_PROPERTIES}
-- Parametres : ...
--    build   : ${_OPTS_RUN_BUILD}
--    data    : ${_OPTS_RUN_DATA}
--    json    : ${_OPTS_RUN_JSON}
--    info    : ${_OPTS_RUN_INFO}
--    git     : ${_OPTS_RUN_COMMIT}
--    publish : ${_OPTS_RUN_PUBLISH}
--    clean   : ${_OPTS_RUN_CLEAN}
-- Information   : ...
--    depot Git : ${GIT_REPOSITORY}
----------------------------------------------------------

EOF
}

##########
# main ()

info

printTo "BEGIN"

################################################################################
printTo "--> build..."

if [ ${_OPTS_RUN_BUILD} == true ]
then
  doCmd "cd ${_PWD}"
  doCmd "gulp --${_LIBRARY}" > /dev/null 2>&1
  doCmd "gulp publish --${_LIBRARY}" > /dev/null 2>&1
  doCmd "gulp --production --${_LIBRARY}" > /dev/null 2>&1
  doCmd "gulp publish --${_LIBRARY}" > /dev/null 2>&1
fi

################################################################################
printTo "--> data"

if [ ${_OPTS_RUN_DATA} == true ]
then
  doCmd "cd ${_PWD}"
  # git clone https://github.com/lowzonenose/geoportal-extensions-leaflet.git
  doCmd "git clone ${GIT_REPOSITORY} ${GIT_DIR_PUBLISH}"
  # cp -r dist/leaflet geoportal-extensions-leaflet/dist
  doCmd "cp -r ${_DIR_DIST}/${_LIBRARY}/. ${GIT_DIR_PUBLISH}/dist"
  # cp LICENCE.md geoportal-extensions-leaflet/
  doCmd "cp LICENCE.md ${GIT_DIR_PUBLISH}"
  # cp README-leaflet.md geoportal-extensions-leaflet/README.md
  doCmd "cp README-leaflet.md ${GIT_DIR_PUBLISH}/README.md"
  # cp CHANGELOG_DRAFT.md geoportal-extensions-leaflet/CHANGELOG.md
  doCmd "cp CHANGELOG_DRAFT.md ${GIT_DIR_PUBLISH}/CHANGELOG.md"
fi

################################################################################
printTo "--> json"

# version API
_PACKAGE_VERSION=$(cat package.json | perl -MJSON -0ne 'my $DS = decode_json $_;print $DS->{version};')

if [ ${_OPTS_RUN_JSON} == true ]
then
  [ -d ${GIT_DIR_PUBLISH} ] && {
    # contenu du package.json avec version API
    _PACKAGE_CONTENT=$(cat ${GIT_DIR_PUBLISH}/package.json |
        perl -MJSON -0ne '
          my $DS = decode_json $_;
          $DS->{version} = ${_PACKAGE_VERSION};
          print encode_json $DS
          ')
    # contenu du bower.json avec version API
    _BOWER_CONTENT=$(cat ${GIT_DIR_PUBLISH}/bower.json |
        perl -MJSON -0ne '
          my $DS = decode_json $_;
          $DS->{version} = ${_PACKAGE_VERSION};
          print encode_json $DS
          ')

    doCmd "cd ${_PWD}"
    doCmd "echo ${_PACKAGE_CONTENT} > ${GIT_DIR_PUBLISH}/package.json"
    doCmd "echo ${_BOWER_CONTENT} > ${GIT_DIR_PUBLISH}/bower.json"
  }
fi

################################################################################
printTo "--> info"

# TODO informations sur la construcion des binaires
# Ex. date, version, size, md5, ...
if [ ${_OPTS_RUN_INFO} == true ]
then
  [ -d ${GIT_DIR_PUBLISH} ] && {
    _INFO_CONTENT=$(cat ${GIT_DIR_PUBLISH}/summary.json |
    perl -MJSON -0ne '
      my $DS = decode_json $_;
      $DS->{version} = "...";
      $DS->{date} = "...";
      print encode_json $DS
    ')
    echo ${_INFO_CONTENT} > "${GIT_DIR_PUBLISH}/summary.json"
  }
fi

################################################################################
printTo "--> git"

# FIXME git push : authentification ?
if [ ${_OPTS_RUN_COMMIT} == true ]
then
  [ -d ${GIT_DIR_PUBLISH} ] && {
    doCmd "cd ${GIT_DIR_PUBLISH}"
    doCmd "git add -Af"
    message=$(echo ${GIT_COMMIT_MESSAGE} |
        sed -e "s@%version%@${_PACKAGE_VERSION}@g" |
        sed -e "s@%library%@${_LIBRARY}@g")
    doCmd "git commit -m \"$message\""

    if [ -n ${GIT_TOKEN} ]; then
      _GIT_REPOSITORY_TOKEN=$(echo ${GIT_REPOSITORY} | sed -e "s/github.com/${GIT_USERNAME}:${GIT_TOKEN}@github.com/")
      doCmd "git remote set-url origin ${_GIT_REPOSITORY_TOKEN}"
    fi

    doCmd "git push"
  }
fi

###############################################################################
printTo "--> publish"

# FIXME npm / bower : authentification ?
if [ ${_OPTS_RUN_PUBLISH} == true ]
then
  [ -d ${GIT_DIR_PUBLISH} ] && {
    doCmd "cd ${GIT_DIR_PUBLISH}"
    # npm publish
    doCmd ""
    # npm install bower
    doCmd ""
    # bower register geoportal-extensions-leaflet http://github.com/IGNF/geoportal-extensions-leaflet.git
    doCmd ""
  }
fi

###############################################################################
printTo "--> clean"

if [ ${_OPTS_RUN_CLEAN} == true ]
then
  doCmd "cd ${_PWD}"
  doCmd "rm -rf ${GIT_DIR_PUBLISH}"
fi

printTo "END"

# set +x

exit 0
