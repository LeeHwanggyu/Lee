#!/bin/bash
####################################################################################################
# 
# Amazon Connect環境ユーザー設定（ユーザー管理）
# 
####################################################################################################

#####################################################################
# AWS環境情報
#####################################################################

#-------------------------------------------------------------------------
# AWSアカウント
#-------------------------------------------------------------------------
Target_Aws_Account=643024316992

#-------------------------------------------------------------------------
# 作成リージョン
#-------------------------------------------------------------------------
Target_Region=ap-northeast-1

#-------------------------------------------------------------------------
# AmazonConnectインスタンス名（エイリアス）
#-------------------------------------------------------------------------
Name_AmazonConnect_Instance=biz-merge-cti-stg




#-------------------------------------------------------------------------
# 認証方法
#  SAML               ：SAML2.0ベース認証
#  CONNECT_MANAGED    ：Amazon Connectでユーザーを作成および管理
#  EXISTING_DIRECTORY ：既存のディレクトリへのリンク
#-------------------------------------------------------------------------
Identity_Management_Type=SAML

#-------------------------------------------------------------------------
# ログファイル名
#-------------------------------------------------------------------------
OUTPUT_FILE1=U1_error_log.txt
#>${OUTPUT_FILE1}


OUTPUT_FILE4=U1_INPUT_Counter.txt
OUTPUT_FILE5=U1_OUTPUT_processed-users.txt

#-------------------------------------------------------------------------
# ワークファイル名
#-------------------------------------------------------------------------
Work_List=Work_List.work
Work_Data1=Work_Data1.work
Work_Data2=Work_Data2.work
Work_Data3=Work_Data3.work
Work_Data4=Work_Data4.work
Work_Data5=Work_Data5.work
Work_Data6=Work_Data6.work
Work_UsersList=U1_Work_UsersList.work

#-------------------------------------------------------------------------
# 環境変数設定
#-------------------------------------------------------------------------
export AWS_MAX_ATTEMPTS=50


echo ◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇
echo ◇
echo ◇  Amazon Connect環境ユーザー設定（ユーザー管理）を開始します。
echo ◇
echo ◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇

echo ◇　前処理
echo ◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇
echo ◇

#-------------------------------------------------------------------------
# 引数チェック
#-------------------------------------------------------------------------
if [ $# != 1 ]; then
  echo ◆　指定された引数は $# 個です。
  echo ◆　実行するにはユーザーファイルを１つ指定する必要があります。
  unset AWS_MAX_ATTEMPTS
  exit 10
else
  File_users_list=$1
  echo ◇　ユーザーファイル（${File_users_list}）が指定されました。
fi

#-------------------------------------------------------------------------
# 変数ファイルの読み込み
#-------------------------------------------------------------------------
if ! test -r ./${File_users_list} ;then
  echo ◆　ユーザーファイル（${File_users_list}）が読めません。
  echo ◆　処理を終了します。
  unset AWS_MAX_ATTEMPTS
  exit 10
fi


#-------------------------------------------------------------------------
# 環境チェック：アカウントチェック
#-------------------------------------------------------------------------
My_Aws_Account=`aws --region ${Target_Region} sts get-caller-identity --output json | jq -r '.Account'`
if [ "${My_Aws_Account}" != "${Target_Aws_Account}" ] ; then
  echo ◆　環境変数で指定のアカウントと実行環境に相違があります。
  echo ◆　　設定アカウント：${Target_Aws_Account}
  echo ◆　　実行アカウント：${My_Aws_Account}
  echo ◆　処理を終了します。
  unset AWS_MAX_ATTEMPTS
  exit 10
else
  echo ◇　環境変数で指定のアカウントと実行環境に相違なし。
  echo ◇　　設定アカウント：${Target_Aws_Account}
  echo ◇　　実行アカウント：${My_Aws_Account}
  echo ◇　
fi

#-------------------------------------------------------------------------
# 環境チェック：実行ユーザー表示
#-------------------------------------------------------------------------
My_Aws_User=`aws --region ${Target_Region} sts get-caller-identity --output json | jq -r '.Arn'`
echo ◇　実行ユーザーは（${My_Aws_User}）です。


#-------------------------------------------------------------------------
# インスタンス有無チェック
#-------------------------------------------------------------------------
aws --region ${Target_Region} connect list-instances  --output json | grep InstanceAlias | grep \"${Name_AmazonConnect_Instance}\" >/dev/null
RC=$?
if [ ${RC} -ne 0 ] ; then
  echo ◆　AmazonConnectのインスタンス（${Name_AmazonConnect_Instance}）が存在しません。
  echo ◆　処理を終了します。
  unset AWS_MAX_ATTEMPTS
  exit 10
else
  echo ◇　AmazonConnectのインスタンス（${Name_AmazonConnect_Instance}）が存在することを確認
  echo ◇　
fi
# インスタンスID取得
ID_AmazonConnect=`aws --region ${Target_Region} connect list-instances  --output text | grep $'\t'${Name_AmazonConnect_Instance}$'\t' | sed -e "s/^[^\t]*\t[^\t]*\t[^\t]*\t\([^\t]*\)\t.*$/\1/"`




OUTPUT_FILE3=${File_users_list}

echo ◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇
echo ◇　実行状態の確認
echo ◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇
echo ◇

if [ -s ./${OUTPUT_FILE3} ] && [ -s ./${OUTPUT_FILE4} ] && [ -s ./${OUTPUT_FILE5} ] ; then
  . ./${OUTPUT_FILE4}
  echo ◇　仕掛かり中のユーザー情報が存在します。
  echo ◇　　処理レコード数　　：${User_CNT}
  echo ◇　　総レコード数　　　：${Max_CNT}
  echo ◇　　処理開始日時　　　：${User_START_TIME}
  echo ◇　処理を継続しますか？（Y/N）
  Check_INPUT=
  while true
  do
    read  Check_INPUT
    
    if [ "${Check_INPUT}" = "Y" -o "${Check_INPUT}" = "y" ];then
      echo ◇　処理を継続します。
      echo ◇
      
      echo ◇◇◇◇◇◇◇◇ >>${OUTPUT_FILE1}
      echo ◇　処理再開　◇ >>${OUTPUT_FILE1}
      echo ◇◇◇◇◇◇◇◇ >>${OUTPUT_FILE1}
      
      break
    fi
    
    if [ "${Check_INPUT}" = "N" -o "${Check_INPUT}" = "n" ];then
      echo ◆　処理を終了します。
      echo ◆　一から処理する場合、以下のファイルを削除して下さい。
      echo ◆　　削除対象：${OUTPUT_FILE4}
      echo ◆　　　　　　　${OUTPUT_FILE5}
      unset AWS_MAX_ATTEMPTS
      exit 10
    fi
    echo ◇　もう一度入力してください。
    echo ◇　処理を継続しますか？（Y/N）
  done
  
  
  
else
  echo ◇　仕掛かり中のユーザー情報が存在しません。
  
  echo ◇　一から処理を実施しますか？（Y/N）
  Check_INPUT=
  while true
  do
    read  Check_INPUT
    
    if [ "${Check_INPUT}" = "Y" -o "${Check_INPUT}" = "y" ];then
      echo ◇　処理を実施します。
      
      break
    fi
    
    if [ "${Check_INPUT}" = "N" -o "${Check_INPUT}" = "n" ];then
      echo ◆　処理を終了します。
      unset AWS_MAX_ATTEMPTS
      exit 10
    fi
    echo ◇　もう一度入力してください。
    echo ◇　処理を実施しますか？（Y/N）
  done
  
  # 引継ぎファイルの初期化
  >${OUTPUT_FILE1}
  >${OUTPUT_FILE5}



  User_CNT=0
  Max_CNT=`cat ${OUTPUT_FILE3} | wc -l`
  
  echo User_CNT=${User_CNT}> ${OUTPUT_FILE4}
  echo Max_CNT=${Max_CNT}>> ${OUTPUT_FILE4}
  User_START_TIME=`TZ=JST-9 date +"%Y/%m/%d %H:%M:%S"`
  echo User_START_TIME=\"${User_START_TIME}\">> ${OUTPUT_FILE4}
  
  echo ◇
  echo ◇　総レコード数は${Max_CNT}件です。
  echo ◇　処理開始日時は${User_START_TIME}です。
  echo ◇

fi


#-------------------------------------------------------------------------
# ユーザー管理
#-------------------------------------------------------------------------
echo ◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇
echo ◇　ユーザー管理処理
echo ◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇
echo ◇
echo ◇　ユーザー一覧を取得します。
aws --region ${Target_Region} connect list-users  --instance-id  ${ID_AmazonConnect} --output text > ${Work_List}
RC=$?
if [ "${RC}" != "0" ] ;then
  rm -f ${Work_List}
  echo ◆
  echo ◆　ユーザー一覧の取得に失敗しました。（RC=${RC}）
  echo ◆　処理を中断します。
  unset AWS_MAX_ATTEMPTS
  echo ◆　ユーザー一覧の取得に失敗しました。（RC=${RC}）>>${OUTPUT_FILE1}
  echo ◆　処理を中断します。>>${OUTPUT_FILE1}
  exit 10
fi

if [ "${File_users_list}" != "" ];then
  
#  while read line
#  while read line || [ -n "${line}" ]
#  do
  while [ -s ./${OUTPUT_FILE3} ]
  do
    line=`head -n 1 ./${OUTPUT_FILE3}`
    
    User_CNT=`expr ${User_CNT} + 1`
    
    line_1=`echo ${line} | cut -b 1`
    if [ "${line_1}" != "#" ] && [ "${line_1}" != "" ] ;then
      Def_Need=`echo ${line}              | cut -d , -f  1  | sed -e "s/^\"\(.*\)\"$/\1/"`
      Def_Name=`echo ${line}            | cut -d , -f  2  | sed -e "s/^\"\(.*\)\"$/\1/"`
      Def_Last_Name=`echo ${line}       | cut -d , -f  3  | sed -e "s/^\"\(.*\)\"$/\1/"`
      Def_First_Name=`echo ${line}      | cut -d , -f  4  | sed -e "s/^\"\(.*\)\"$/\1/"`
      Def_PW=`echo ${line}              | cut -d , -f  5  | sed -e "s/^\"\(.*\)\"$/\1/"`
      Def_R_Pro=`echo ${line}           | cut -d , -f  6  | sed -e "s/^\"\(.*\)\"$/\1/"`
      Def_S_Pro=`echo ${line}           | cut -d , -f  7  | sed -e "s/^\"\(.*\)\"$/\1/"`
      Def_Mail=`echo ${line}            | cut -d , -f  8  | sed -e "s/^\"\(.*\)\"$/\1/"`
      Def_Q_Connect_Name=`echo ${line}  | cut -d , -f  9  | sed -e "s/^\"\(.*\)\"$/\1/"`
      Def_Q_Connect_Flow=`echo ${line}  | cut -d , -f 10  | sed -e "s/^\"\(.*\)\"$/\1/"`
      Def_Agent_L1=`echo ${line}        | cut -d , -f 11  | sed -e "s/^\"\(.*\)\"$/\1/"`
      Def_Agent_L2=`echo ${line}        | cut -d , -f 12  | sed -e "s/^\"\(.*\)\"$/\1/"`
      Def_Agent_L3=`echo ${line}        | cut -d , -f 13  | sed -e "s/^\"\(.*\)\"$/\1/"`
      Def_Agent_L4=`echo ${line}        | cut -d , -f 14  | sed -e "s/^\"\(.*\)\"$/\1/"`
      Def_Agent_L5=`echo ${line}        | cut -d , -f 15  | sed -e "s/^\"\(.*\)\"$/\1/"`
      Def_ACW=`echo ${line}             | cut -d , -f 16  | sed -e "s/^\"\(.*\)\"$/\1/"`
      Def_PhoneType=`echo ${line}       | cut -d , -f 17  | sed -e "s/^\"\(.*\)\"$/\1/"`
      Def_AutoAccept=`echo ${line}      | cut -d , -f 18  | sed -e "s/^\"\(.*\)\"$/\1/"`
      Def_DeskPhoneNumber=`echo ${line} | cut -d , -f 19  | sed -e "s/^\"\(.*\)\"$/\1/"`
      Def_ETC=`echo ${line}             | cut -d , -f 20  | sed -e "s/^\"\(.*\)\"$/\1/"`
      
      echo ◇
      echo ◇　対象ユーザー（${Def_Name}）の処理を開始します。（${User_CNT}件目）
      
      if [ "${Def_Need}" = "必要" ] ;then
        # Def_Need が「必要」の場合、該当ユーザーを新規作成（または更新）
        
        ###############################################################################
        # エージェント階層の設定
        ###############################################################################
        Def_level_1_ID=
        Def_level_2_ID=
        Def_level_3_ID=
        Def_level_4_ID=
        Def_level_5_ID=
        
        ###############################################################################
        # エージェント階層Level 1
        ###############################################################################
        SEARCH_LEVEL="LEVELONE"
        SEARCH_NAME=${Def_Agent_L1}
        SEARCH_NAME_ALL=${Def_Agent_L1}
        SEARCH_Owner_LEVEL=""
        SEARCH_Owner_ID=""
        GET_ID=
        if [ "${SEARCH_NAME}" != "" ] ;then
          # echo ◇　　エージェント階層（${SEARCH_NAME_ALL}）のIDを取得します。
          
          # 名前と一致するエージェント階層のID取得
          ID_list=`aws --region ${Target_Region} connect list-user-hierarchy-groups --instance-id  ${ID_AmazonConnect} --output text |  grep $'\t'"${SEARCH_NAME}"$  |  sed -e "s/^[^\t]*\t[^\t]*\t\([^\t]*\)\t.*$/\1/"`
          
          # IDの数だけチェックする
          for i in ${ID_list}
          do
            # 該当エージェント階層チェック
            aws --region ${Target_Region} connect describe-user-hierarchy-group --hierarchy-group-id ${i} --instance-id ${ID_AmazonConnect} --output text  \
                        |  grep  ${SEARCH_LEVEL} |  grep $'\t'"${SEARCH_NAME}"$ >/dev/null 2>&1
            RC=$?
            if [ ${RC} -eq 0 ] ; then
              # 該当Levelと名前が一致
              
              if [ "${SEARCH_Owner_LEVEL}" != "" -a "${SEARCH_Owner_NAME}" != "" ] ; then
                # 上位階層が存在（第2～5階層）
                
                # 上位階層のエージェント階層をチェック
                aws --region ${Target_Region} connect describe-user-hierarchy-group --hierarchy-group-id ${i} --instance-id ${ID_AmazonConnect} --output text  \
                            |  grep  ${SEARCH_Owner_LEVEL} |  grep $'\t'"${SEARCH_Owner_ID}"$'\t' >/dev/null 2>&1
                RC=$?
                if [ ${RC} -eq 0 ] ; then
                  # 上位階層IDが一致
                  GET_ID=${i}
                fi
              else
                # 上位階層が無い（第1階層）
                GET_ID=${i}
              fi
            fi
          done
          
          # IDが取得できなかった場合、新規にエージェント階層を作成する。
          if [ "${GET_ID}" = "" ] ;then
            echo ◇　　エージェント階層（${SEARCH_NAME_ALL}）が存在しない為、新規作成します。
            
            # エージェント階層名を新規登録
            if [ "${SEARCH_Owner_LEVEL}" != "" -a "${SEARCH_Owner_NAME}" != "" ] ; then
              GET_ID=`aws --region ${Target_Region} connect create-user-hierarchy-group --instance-id  ${ID_AmazonConnect}  --output  json    \
                                                              --name  "${SEARCH_NAME}" | jq -r .HierarchyGroupId`
              RC=$?
            else
              GET_ID=`aws --region ${Target_Region} connect create-user-hierarchy-group --instance-id  ${ID_AmazonConnect}  --output  json    \
                                                              --name  "${SEARCH_NAME}"  --parent-group-id  "${SEARCH_Owner_ID}" | jq -r .HierarchyGroupId`
              RC=$?
            fi
            
            if [ ${RC} -ne 0 ] ; then
              echo ◆　　エージェント階層（${SEARCH_NAME_ALL}）の作成でエラーが発生しました。（RC=${RC}）
              echo ◆　　ユーザー（${Def_Name}）の設定を中断します。
              echo ◆　　エージェント階層（${SEARCH_NAME_ALL}）の作成でエラーが発生しました。（RC=${RC}）>>${OUTPUT_FILE1}
              echo ◆　　ユーザー（${Def_Name}）の設定を中断します。>>${OUTPUT_FILE1}
              exit 10
            fi
            
            if [ "${GET_ID}" = "" ] ; then
              echo ◆　　エージェント階層（${SEARCH_NAME_ALL}）のIDが取得できませんでした。
              echo ◆　　ユーザー（${Def_Name}）の設定を中断します。
              echo ◆　　エージェント階層（${SEARCH_NAME_ALL}）のIDが取得できませんでした。>>${OUTPUT_FILE1}
              echo ◆　　ユーザー（${Def_Name}）の設定を中断します。>>${OUTPUT_FILE1}
              exit 10
            fi
          else
            echo ◇　　エージェント階層（${SEARCH_NAME_ALL}）が存在することを確認。
          fi
          Def_level_1_ID=${GET_ID}
        fi
        
        ###############################################################################
        # エージェント階層Level 2
        ###############################################################################
        SEARCH_LEVEL="LEVELTWO"
        SEARCH_NAME=${Def_Agent_L2}
        SEARCH_NAME_ALL=${Def_Agent_L1}/${Def_Agent_L2}
        SEARCH_Owner_LEVEL="LEVELONE"
        SEARCH_Owner_ID=${Def_level_1_ID}
        GET_ID=
        if [ "${SEARCH_NAME}" != "" ] ;then
          # echo ◇　　エージェント階層（${SEARCH_NAME_ALL}）のIDを取得します。
          
          # 名前と一致するエージェント階層のID取得
          ID_list=`aws --region ${Target_Region} connect list-user-hierarchy-groups --instance-id  ${ID_AmazonConnect} --output text |  grep $'\t'"${SEARCH_NAME}"$  |  sed -e "s/^[^\t]*\t[^\t]*\t\([^\t]*\)\t.*$/\1/"`
          
          # IDの数だけチェックする
          for i in ${ID_list}
          do
            # 該当エージェント階層チェック
            aws --region ${Target_Region} connect describe-user-hierarchy-group --hierarchy-group-id ${i} --instance-id ${ID_AmazonConnect} --output text  \
                        |  grep  ${SEARCH_LEVEL} |  grep $'\t'"${SEARCH_NAME}"$ >/dev/null 2>&1
            RC=$?
            if [ ${RC} -eq 0 ] ; then
              # 該当Levelと名前が一致
              
              if [ "${SEARCH_Owner_LEVEL}" != "" -a "${SEARCH_Owner_NAME}" != "" ] ; then
                # 上位階層が存在（第2～5階層）
                
                # 上位階層のエージェント階層をチェック
                aws --region ${Target_Region} connect describe-user-hierarchy-group --hierarchy-group-id ${i} --instance-id ${ID_AmazonConnect} --output text  \
                            |  grep  ${SEARCH_Owner_LEVEL} |  grep $'\t'"${SEARCH_Owner_ID}"$'\t' >/dev/null 2>&1
                RC=$?
                if [ ${RC} -eq 0 ] ; then
                  # 上位階層IDが一致
                  GET_ID=${i}
                fi
              else
                # 上位階層が無い（第1階層）
                GET_ID=${i}
              fi
            fi
          done
          
          # IDが取得できなかった場合、新規にエージェント階層を作成する。
          if [ "${GET_ID}" = "" ] ;then
            echo ◇　　エージェント階層（${SEARCH_NAME_ALL}）が存在しない為、新規作成します。
            
            # エージェント階層名を新規登録
            if [ "${SEARCH_Owner_LEVEL}" != "" -a "${SEARCH_Owner_NAME}" != "" ] ; then
              GET_ID=`aws --region ${Target_Region} connect create-user-hierarchy-group --instance-id  ${ID_AmazonConnect}  --output  json    \
                                                              --name  "${SEARCH_NAME}" | jq -r .HierarchyGroupId`
              RC=$?
            else
              GET_ID=`aws --region ${Target_Region} connect create-user-hierarchy-group --instance-id  ${ID_AmazonConnect}  --output  json    \
                                                              --name  "${SEARCH_NAME}"  --parent-group-id  "${SEARCH_Owner_ID}" | jq -r .HierarchyGroupId`
              RC=$?
            fi
            
            if [ ${RC} -ne 0 ] ; then
              echo ◆　　エージェント階層（${SEARCH_NAME_ALL}）の作成でエラーが発生しました。（RC=${RC}）
              echo ◆　　ユーザー（${Def_Name}）の設定を中断します。
              echo ◆　　エージェント階層（${SEARCH_NAME_ALL}）の作成でエラーが発生しました。（RC=${RC}）>>${OUTPUT_FILE1}
              echo ◆　　ユーザー（${Def_Name}）の設定を中断します。>>${OUTPUT_FILE1}
              exit 10
            fi
            
            if [ "${GET_ID}" = "" ] ; then
              echo ◆　　エージェント階層（${SEARCH_NAME_ALL}）のIDが取得できませんでした。
              echo ◆　　ユーザー（${Def_Name}）の設定を中断します。
              echo ◆　　エージェント階層（${SEARCH_NAME_ALL}）のIDが取得できませんでした。>>${OUTPUT_FILE1}
              echo ◆　　ユーザー（${Def_Name}）の設定を中断します。>>${OUTPUT_FILE1}
              exit 10
            fi
          else
            echo ◇　　エージェント階層（${SEARCH_NAME_ALL}）が存在することを確認。
          fi
          Def_level_2_ID=${GET_ID}
        fi      
        
        ###############################################################################
        # エージェント階層Level 3
        ###############################################################################
        SEARCH_LEVEL="LEVELTHREE"
        SEARCH_NAME=${Def_Agent_L3}
        SEARCH_NAME_ALL=${Def_Agent_L1}/${Def_Agent_L2}/${Def_Agent_L3}
        SEARCH_Owner_LEVEL="LEVELTWO"
        SEARCH_Owner_ID=${Def_level_2_ID}
        GET_ID=
        if [ "${SEARCH_NAME}" != "" ] ;then
          # echo ◇　　エージェント階層（${SEARCH_NAME_ALL}）のIDを取得します。
          
          # 名前と一致するエージェント階層のID取得
          ID_list=`aws --region ${Target_Region} connect list-user-hierarchy-groups --instance-id  ${ID_AmazonConnect} --output text |  grep $'\t'"${SEARCH_NAME}"$  |  sed -e "s/^[^\t]*\t[^\t]*\t\([^\t]*\)\t.*$/\1/"`
          
          # IDの数だけチェックする
          for i in ${ID_list}
          do
            # 該当エージェント階層チェック
            aws --region ${Target_Region} connect describe-user-hierarchy-group --hierarchy-group-id ${i} --instance-id ${ID_AmazonConnect} --output text  \
                        |  grep  ${SEARCH_LEVEL} |  grep $'\t'"${SEARCH_NAME}"$ >/dev/null 2>&1
            RC=$?
            if [ ${RC} -eq 0 ] ; then
              # 該当Levelと名前が一致
              
              if [ "${SEARCH_Owner_LEVEL}" != "" -a "${SEARCH_Owner_NAME}" != "" ] ; then
                # 上位階層が存在（第2～5階層）
                
                # 上位階層のエージェント階層をチェック
                aws --region ${Target_Region} connect describe-user-hierarchy-group --hierarchy-group-id ${i} --instance-id ${ID_AmazonConnect} --output text  \
                            |  grep  ${SEARCH_Owner_LEVEL} |  grep $'\t'"${SEARCH_Owner_ID}"$'\t' >/dev/null 2>&1
                RC=$?
                if [ ${RC} -eq 0 ] ; then
                  # 上位階層IDが一致
                  GET_ID=${i}
                fi
              else
                # 上位階層が無い（第1階層）
                GET_ID=${i}
              fi
            fi
          done
          
          # IDが取得できなかった場合、新規にエージェント階層を作成する。
          if [ "${GET_ID}" = "" ] ;then
            echo ◇　　エージェント階層（${SEARCH_NAME_ALL}）が存在しない為、新規作成します。
            
            # エージェント階層名を新規登録
            if [ "${SEARCH_Owner_LEVEL}" != "" -a "${SEARCH_Owner_NAME}" != "" ] ; then
              GET_ID=`aws --region ${Target_Region} connect create-user-hierarchy-group --instance-id  ${ID_AmazonConnect}  --output  json    \
                                                              --name  "${SEARCH_NAME}" | jq -r .HierarchyGroupId`
              RC=$?
            else
              GET_ID=`aws --region ${Target_Region} connect create-user-hierarchy-group --instance-id  ${ID_AmazonConnect}  --output  json    \
                                                              --name  "${SEARCH_NAME}"  --parent-group-id  "${SEARCH_Owner_ID}" | jq -r .HierarchyGroupId`
              RC=$?
            fi
            
            if [ ${RC} -ne 0 ] ; then
              echo ◆　　エージェント階層（${SEARCH_NAME_ALL}）の作成でエラーが発生しました。（RC=${RC}）
              echo ◆　　ユーザー（${Def_Name}）の設定を中断します。
              echo ◆　　エージェント階層（${SEARCH_NAME_ALL}）の作成でエラーが発生しました。（RC=${RC}）>>${OUTPUT_FILE1}
              echo ◆　　ユーザー（${Def_Name}）の設定を中断します。>>${OUTPUT_FILE1}
              exit 10
            fi
            
            if [ "${GET_ID}" = "" ] ; then
              echo ◆　　エージェント階層（${SEARCH_NAME_ALL}）のIDが取得できませんでした。
              echo ◆　　ユーザー（${Def_Name}）の設定を中断します。
              echo ◆　　エージェント階層（${SEARCH_NAME_ALL}）のIDが取得できませんでした。>>${OUTPUT_FILE1}
              echo ◆　　ユーザー（${Def_Name}）の設定を中断します。>>${OUTPUT_FILE1}
              exit 10
            fi
          else
            echo ◇　　エージェント階層（${SEARCH_NAME_ALL}）が存在することを確認。
          fi
          Def_level_3_ID=${GET_ID}
        fi       
        
        ###############################################################################
        # エージェント階層Level 4
        ###############################################################################
        SEARCH_LEVEL="LEVELFOUR"
        SEARCH_NAME=${Def_Agent_L4}
        SEARCH_NAME_ALL=${Def_Agent_L1}/${Def_Agent_L2}/${Def_Agent_L3}/${Def_Agent_L4}
        SEARCH_Owner_LEVEL="LEVELTHREE"
        SEARCH_Owner_ID=${Def_level_3_ID}
        GET_ID=
        if [ "${SEARCH_NAME}" != "" ] ;then
          # echo ◇　　エージェント階層（${SEARCH_NAME_ALL}）のIDを取得します。
          
          # 名前と一致するエージェント階層のID取得
          ID_list=`aws --region ${Target_Region} connect list-user-hierarchy-groups --instance-id  ${ID_AmazonConnect} --output text |  grep $'\t'"${SEARCH_NAME}"$  |  sed -e "s/^[^\t]*\t[^\t]*\t\([^\t]*\)\t.*$/\1/"`
          
          # IDの数だけチェックする
          for i in ${ID_list}
          do
            # 該当エージェント階層チェック
            aws --region ${Target_Region} connect describe-user-hierarchy-group --hierarchy-group-id ${i} --instance-id ${ID_AmazonConnect} --output text  \
                        |  grep  ${SEARCH_LEVEL} |  grep $'\t'"${SEARCH_NAME}"$ >/dev/null 2>&1
            RC=$?
            if [ ${RC} -eq 0 ] ; then
              # 該当Levelと名前が一致
              
              if [ "${SEARCH_Owner_LEVEL}" != "" -a "${SEARCH_Owner_NAME}" != "" ] ; then
                # 上位階層が存在（第2～5階層）
                
                # 上位階層のエージェント階層をチェック
                aws --region ${Target_Region} connect describe-user-hierarchy-group --hierarchy-group-id ${i} --instance-id ${ID_AmazonConnect} --output text  \
                            |  grep  ${SEARCH_Owner_LEVEL} |  grep $'\t'"${SEARCH_Owner_ID}"$'\t' >/dev/null 2>&1
                RC=$?
                if [ ${RC} -eq 0 ] ; then
                  # 上位階層IDが一致
                  GET_ID=${i}
                fi
              else
                # 上位階層が無い（第1階層）
                GET_ID=${i}
              fi
            fi
          done
          
          # IDが取得できなかった場合、新規にエージェント階層を作成する。
          if [ "${GET_ID}" = "" ] ;then
            echo ◇　　エージェント階層（${SEARCH_NAME_ALL}）が存在しない為、新規作成します。
            
            # エージェント階層名を新規登録
            if [ "${SEARCH_Owner_LEVEL}" != "" -a "${SEARCH_Owner_NAME}" != "" ] ; then
              GET_ID=`aws --region ${Target_Region} connect create-user-hierarchy-group --instance-id  ${ID_AmazonConnect}  --output  json    \
                                                              --name  "${SEARCH_NAME}" | jq -r .HierarchyGroupId`
              RC=$?
            else
              GET_ID=`aws --region ${Target_Region} connect create-user-hierarchy-group --instance-id  ${ID_AmazonConnect}  --output  json    \
                                                              --name  "${SEARCH_NAME}"  --parent-group-id  "${SEARCH_Owner_ID}" | jq -r .HierarchyGroupId`
              RC=$?
            fi
            
            if [ ${RC} -ne 0 ] ; then
              echo ◆　　エージェント階層（${SEARCH_NAME_ALL}）の作成でエラーが発生しました。（RC=${RC}）
              echo ◆　　ユーザー（${Def_Name}）の設定を中断します。
              echo ◆　　エージェント階層（${SEARCH_NAME_ALL}）の作成でエラーが発生しました。（RC=${RC}）>>${OUTPUT_FILE1}
              echo ◆　　ユーザー（${Def_Name}）の設定を中断します。>>${OUTPUT_FILE1}
              exit 10
            fi
            
            if [ "${GET_ID}" = "" ] ; then
              echo ◆　　エージェント階層（${SEARCH_NAME_ALL}）のIDが取得できませんでした。
              echo ◆　　ユーザー（${Def_Name}）の設定を中断します。
              echo ◆　　エージェント階層（${SEARCH_NAME_ALL}）のIDが取得できませんでした。>>${OUTPUT_FILE1}
              echo ◆　　ユーザー（${Def_Name}）の設定を中断します。>>${OUTPUT_FILE1}
              exit 10
            fi
          else
            echo ◇　　エージェント階層（${SEARCH_NAME_ALL}）が存在することを確認。
          fi
          Def_level_4_ID=${GET_ID}
        fi             
        
        ###############################################################################
        # エージェント階層Level 5
        ###############################################################################
        SEARCH_LEVEL="LEVELFIVE"
        SEARCH_NAME=${Def_Agent_L5}
        SEARCH_NAME_ALL=${Def_Agent_L1}/${Def_Agent_L2}/${Def_Agent_L3}/${Def_Agent_L4}/${Def_Agent_L5}
        SEARCH_Owner_LEVEL="LEVELFOUR"
        SEARCH_Owner_ID=${Def_level_4_ID}
        GET_ID=
        if [ "${SEARCH_NAME}" != "" ] ;then
          # echo ◇　　エージェント階層（${SEARCH_NAME_ALL}）のIDを取得します。
          
          # 名前と一致するエージェント階層のID取得
          ID_list=`aws --region ${Target_Region} connect list-user-hierarchy-groups --instance-id  ${ID_AmazonConnect} --output text |  grep $'\t'"${SEARCH_NAME}"$  |  sed -e "s/^[^\t]*\t[^\t]*\t\([^\t]*\)\t.*$/\1/"`
          
          # IDの数だけチェックする
          for i in ${ID_list}
          do
            # 該当エージェント階層チェック
            aws --region ${Target_Region} connect describe-user-hierarchy-group --hierarchy-group-id ${i} --instance-id ${ID_AmazonConnect} --output text  \
                        |  grep  ${SEARCH_LEVEL} |  grep $'\t'"${SEARCH_NAME}"$ >/dev/null 2>&1
            RC=$?
            if [ ${RC} -eq 0 ] ; then
              # 該当Levelと名前が一致
              
              if [ "${SEARCH_Owner_LEVEL}" != "" -a "${SEARCH_Owner_NAME}" != "" ] ; then
                # 上位階層が存在（第2～5階層）
                
                # 上位階層のエージェント階層をチェック
                aws --region ${Target_Region} connect describe-user-hierarchy-group --hierarchy-group-id ${i} --instance-id ${ID_AmazonConnect} --output text  \
                            |  grep  ${SEARCH_Owner_LEVEL} |  grep $'\t'"${SEARCH_Owner_ID}"$'\t' >/dev/null 2>&1
                RC=$?
                if [ ${RC} -eq 0 ] ; then
                  # 上位階層IDが一致
                  GET_ID=${i}
                fi
              else
                # 上位階層が無い（第1階層）
                GET_ID=${i}
              fi
            fi
          done
          
          # IDが取得できなかった場合、新規にエージェント階層を作成する。
          if [ "${GET_ID}" = "" ] ;then
            echo ◇　　エージェント階層（${SEARCH_NAME_ALL}）が存在しない為、新規作成します。
            
            # エージェント階層名を新規登録
            if [ "${SEARCH_Owner_LEVEL}" != "" -a "${SEARCH_Owner_NAME}" != "" ] ; then
              GET_ID=`aws --region ${Target_Region} connect create-user-hierarchy-group --instance-id  ${ID_AmazonConnect}  --output  json    \
                                                              --name  "${SEARCH_NAME}" | jq -r .HierarchyGroupId`
              RC=$?
            else
              GET_ID=`aws --region ${Target_Region} connect create-user-hierarchy-group --instance-id  ${ID_AmazonConnect}  --output  json    \
                                                              --name  "${SEARCH_NAME}"  --parent-group-id  "${SEARCH_Owner_ID}" | jq -r .HierarchyGroupId`
              RC=$?
            fi
            
            if [ ${RC} -ne 0 ] ; then
              echo ◆　　エージェント階層（${SEARCH_NAME_ALL}）の作成でエラーが発生しました。（RC=${RC}）
              echo ◆　　ユーザー（${Def_Name}）の設定を中断します。
              echo ◆　　エージェント階層（${SEARCH_NAME_ALL}）の作成でエラーが発生しました。（RC=${RC}）>>${OUTPUT_FILE1}
              echo ◆　　ユーザー（${Def_Name}）の設定を中断します。>>${OUTPUT_FILE1}
              exit 10
            fi
            
            if [ "${GET_ID}" = "" ] ; then
              echo ◆　　エージェント階層（${SEARCH_NAME_ALL}）のIDが取得できませんでした。
              echo ◆　　ユーザー（${Def_Name}）の設定を中断します。
              echo ◆　　エージェント階層（${SEARCH_NAME_ALL}）のIDが取得できませんでした。>>${OUTPUT_FILE1}
              echo ◆　　ユーザー（${Def_Name}）の設定を中断します。>>${OUTPUT_FILE1}
              exit 10
            fi
          else
            echo ◇　　エージェント階層（${SEARCH_NAME_ALL}）が存在することを確認。
          fi
          Def_level_5_ID=${GET_ID}
        fi
        
        
        ###############################################################################
        # ユーザーの設定
        ###############################################################################
        
        # ルーティングプロファイルのID取得
        ID_routing_profile=`aws --region ${Target_Region} connect list-routing-profiles  --instance-id  ${ID_AmazonConnect} --output text | grep $'\t'"${Def_R_Pro}"$  |  \
                            sed -e "s/^[^\t]*\t[^\t]*\t\([^\t]*\)\t.*$/\1/"`
        if [ "${ID_routing_profile}" = "" ] ;then
          echo ◆　　ユーザー（${Def_Name}）のルーティングプロファイル（${Def_R_Pro}）のIDが取得できませんでした。
          echo ◆　　ユーザー（${Def_Name}）の設定を中断します。
          echo ◆　　ユーザー（${Def_Name}）のルーティングプロファイル（${Def_R_Pro}）のIDが取得できませんでした。>>${OUTPUT_FILE1}
          echo ◆　　ユーザー（${Def_Name}）の設定を中断します。>>${OUTPUT_FILE1}
          exit 10
        fi
        
        # セキュリティプロファイルのID取得
        ID_security_profiles=`aws --region ${Target_Region} connect list-security-profiles  --instance-id  ${ID_AmazonConnect} --output text | grep $'\t'"${Def_S_Pro}"$   | \
                              sed -e "s/^[^\t]*\t[^\t]*\t\([^\t]*\)\t.*$/\1/"`
        if [ "${ID_security_profiles}" = "" ] ;then
          echo ◆　　ユーザー（${Def_Name}）のセキュリティプロファイル（${Def_S_Pro}）のIDが取得できませんでした。
          echo ◆　　ユーザー（${Def_Name}）の設定を中断します。
          echo ◆　　ユーザー（${Def_Name}）のセキュリティプロファイル（${Def_S_Pro}）のIDが取得できませんでした。>>${OUTPUT_FILE1}
          echo ◆　　ユーザー（${Def_Name}）の設定を中断します。>>${OUTPUT_FILE1}
          exit 10
        fi
        
        #######################################
        # 個人情報設定（--identity-info）
        #######################################
        C_identity_info=
        
        # FirstName
        if [ "${Def_First_Name}" != "" ];then
          C_identity_info="${C_identity_info}FirstName=${Def_First_Name},"
        else
          echo ◆　　ユーザー（${Def_Name}）の名が設定されていません。
          echo ◆　　ユーザー（${Def_Name}）の設定を中断します。
          echo ◆　　ユーザー（${Def_Name}）の名が設定されていません。>>${OUTPUT_FILE1}
          echo ◆　　ユーザー（${Def_Name}）の設定を中断します。>>${OUTPUT_FILE1}
          exit 10
        fi
        
        # LastName
        if [ "${Def_Last_Name}" != "" ];then
          C_identity_info="${C_identity_info}LastName=${Def_Last_Name},"
        else
          echo ◆　　ユーザー（${Def_Name}）の姓が設定されていません。
          echo ◆　　ユーザー（${Def_Name}）の設定を中断します。
          echo ◆　　ユーザー（${Def_Name}）の姓が設定されていません。>>${OUTPUT_FILE1}
          echo ◆　　ユーザー（${Def_Name}）の設定を中断します。>>${OUTPUT_FILE1}
          exit 10
        fi
        
        # E-Mail
        if [ "${Identity_Management_Type}" != "SAML" ] ; then
          if [ "${Def_Mail}" != "" ];then
            C_identity_info="${C_identity_info}Email=${Def_Mail},"
          fi
        fi
        
        # カンマを除外
        if [ "${C_identity_info}" != "" ];then
          C_identity_info=${C_identity_info::-1}
#          C_identity_info=" --identity-info ${C_identity_info}"
        fi
        
        #######################################
        # 電話（--phone-config）
        #######################################
        C_phone_config=
        
        # 電話の種類
        if [ "${Def_PhoneType}" = "ソフトフォン" ];then
          C_phone_config="${C_phone_config}PhoneType=SOFT_PHONE,"
        fi
        if [ "${Def_PhoneType}" = "デスクフォン" ];then
          C_phone_config="${C_phone_config}PhoneType=DESK_PHONE,"
        fi
        
        # 通話の自動着信
        if [ "${Def_AutoAccept}" = "いいえ" ];then
          C_phone_config="${C_phone_config}AutoAccept=false,"
        fi
        if [ "${Def_AutoAccept}" = "はい" ];then
          C_phone_config="${C_phone_config}AutoAccept=true,"
        fi
        
        # ACWタイムアウト
        if [ "${Def_ACW}" != "" ];then
          C_phone_config="${C_phone_config}AfterContactWorkTimeLimit=${Def_ACW},"
        fi
        
        # デスクの電話番号
        if [ "${Def_DeskPhoneNumber}" != ""  -a "${Def_DeskPhoneNumber}" != "-" -a "${Def_DeskPhoneNumber}" != "－" ];then
          C_phone_config="${C_phone_config}DeskPhoneNumber=${Def_DeskPhoneNumber},"
        fi
        
        # カンマを除外
        if [ "${C_phone_config}" != "" ];then
          C_phone_config=${C_phone_config::-1}
          C_phone_config=" --phone-config ${C_phone_config}"
        fi
        
        #######################################
        # エージェント階層（--hierarchy-group-id）
        #######################################
        C_hierarchy_group_id=
        if [ "${Def_level_5_ID}" != "" ];then
          C_hierarchy_group_id=" --hierarchy-group-id ${Def_level_5_ID}"
        else
          if [ "${Def_level_4_ID}" != "" ];then
            C_hierarchy_group_id=" --hierarchy-group-id ${Def_level_4_ID}"
          else
            if [ "${Def_level_3_ID}" != "" ];then
              C_hierarchy_group_id=" --hierarchy-group-id ${Def_level_3_ID}"
            else
              if [ "${Def_level_2_ID}" != "" ];then
                C_hierarchy_group_id=" --hierarchy-group-id ${Def_level_2_ID}"
              else
                if [ "${Def_level_1_ID}" != "" ];then
                  C_hierarchy_group_id=" --hierarchy-group-id ${Def_level_1_ID}"
                  
                fi
              fi
            fi
          fi
        fi
        
        # ユーザー有無チェック
#        aws --region ${Target_Region} connect list-users --instance-id ${ID_AmazonConnect} --output json | jq -r .UserSummaryList[].Username  | grep  "^${Def_Name}$" >/dev/null 2>&1
        cat ${Work_List} | grep  $'\t'"${Def_Name}"$ >/dev/null 2>&1
        RC=$?
        if [ ${RC} -ne 0 ] ; then
          # ユーザー無し
          echo ◇　　ユーザー（${Def_Name}）を新規作成します。
          aws --region ${Target_Region} connect create-user  \
             --username ${Def_Name}  \
             --identity-info "${C_identity_info}"  \
             ${C_phone_config}  \
             --security-profile-id ${ID_security_profiles}   \
             --routing-profile-id  ${ID_routing_profile}   \
             ${C_hierarchy_group_id}  \
             --instance-id ${ID_AmazonConnect}   \
             --output text > ${Work_Data1}
          RC=$?
          if [ ${RC} -ne 0 ] ; then
            echo ◆　　ユーザー（${Def_Name}）の新規作成でエラーが発生しました。（RC=${RC}）
            echo ◆　　ユーザー（${Def_Name}）の設定を中断します。
            echo ◆　　ユーザー（${Def_Name}）の新規作成でエラーが発生しました。（RC=${RC}）>>${OUTPUT_FILE1}
            echo ◆　　ユーザー（${Def_Name}）の設定を中断します。>>${OUTPUT_FILE1}
            rm -f  ${Work_Data1}
            exit 10
          else
            echo ◇　　ユーザー（${Def_Name}）の新規作成が完了しました。
            echo ◇　　ユーザー一覧にユーザー（${Def_Name}）を追加します。
            cat ${Work_Data1} | sed "s/^\([^\t]*\)\t[^\t]*$/\1/" >  ${Work_Data2}
            cat ${Work_Data1} | sed "s/^[^\t]*\t\([^\t]*\)$/\1/" >  ${Work_Data3}
            
            echo -e "USERSUMMARYLIST"$'\t'`cat ${Work_Data2}`$'\t'`cat ${Work_Data3}`$'\t'${Def_Name}>>${Work_List}
            rm -f  ${Work_Data1}
            rm -f  ${Work_Data2}
            rm -f  ${Work_Data3}
          fi
        else
          # ユーザー有り
          echo ◇　　ユーザー（${Def_Name}）を更新します。
          
          # ユーザーID取得
#          ID_User=`aws --region ${Target_Region} connect list-users  --instance-id  ${ID_AmazonConnect} --output text | grep $'\t'"${Def_Name}$" | sed -e "s/^[^\t]*\t[^\t]*\t\([^\t]*\)\t.*$/\1/"`
          ID_User=`cat ${Work_List} | grep $'\t'"${Def_Name}$" | sed -e "s/^[^\t]*\t[^\t]*\t\([^\t]*\)\t.*$/\1/"`
          RC=$?
          if [ ${RC} -ne 0 ] ; then
            echo ◆　　ユーザー（${Def_Name}）のID取得でエラーが発生しました。（RC=${RC}）
            echo ◆　　ユーザー（${Def_Name}）の設定を中断します。
            echo ◆　　ユーザー（${Def_Name}）のID取得でエラーが発生しました。（RC=${RC}）>>${OUTPUT_FILE1}
            echo ◆　　ユーザー（${Def_Name}）の設定を中断します。>>${OUTPUT_FILE1}
            exit 10
          fi
          
          #######################################
          # 個人情報設定（--identity-info）
          #######################################
          aws --region ${Target_Region} connect update-user-identity-info  \
             --user-id ${ID_User}   \
             --identity-info "${C_identity_info}"  \
             --instance-id ${ID_AmazonConnect}   \
             --output text
          RC=$?
          if [ ${RC} -ne 0 ] ; then
            echo ◆　　ユーザー（${Def_Name}）の個人情報の更新でエラーが発生しました。（RC=${RC}）
            echo ◆　　ユーザー（${Def_Name}）の設定を中断します。
            echo ◆　　ユーザー（${Def_Name}）の個人情報の更新でエラーが発生しました。（RC=${RC}）>>${OUTPUT_FILE1}
            echo ◆　　ユーザー（${Def_Name}）の設定を中断します。>>${OUTPUT_FILE1}
            exit 10
          else
            echo ◇　　ユーザー（${Def_Name}）の個人情報の更新が完了しました。
          fi        
          
          #######################################
          # 電話（--phone-config）
          #######################################
          aws --region ${Target_Region} connect update-user-phone-config  \
             --user-id ${ID_User}   \
             ${C_phone_config}  \
             --instance-id ${ID_AmazonConnect}   \
             --output text        
          RC=$?
          if [ ${RC} -ne 0 ] ; then
            echo ◆　　ユーザー（${Def_Name}）の電話情報の更新でエラーが発生しました。（RC=${RC}）
            echo ◆　　ユーザー（${Def_Name}）の設定を中断します。
            echo ◆　　ユーザー（${Def_Name}）の電話情報の更新でエラーが発生しました。（RC=${RC}）>>${OUTPUT_FILE1}
            echo ◆　　ユーザー（${Def_Name}）の設定を中断します。>>${OUTPUT_FILE1}
            exit 10
          else
            echo ◇　　ユーザー（${Def_Name}）の電話情報の更新が完了しました。
          fi        
          
          #######################################
          # ルーティングプロファイル
          #######################################
          aws --region ${Target_Region} connect update-user-routing-profile  \
             --user-id ${ID_User}   \
             --routing-profile-id  ${ID_routing_profile}   \
             --instance-id ${ID_AmazonConnect}   \
             --output text
          RC=$?
          if [ ${RC} -ne 0 ] ; then
            echo ◆　　ユーザー（${Def_Name}）のルーティングプロファイルの更新でエラーが発生しました。（RC=${RC}）
            echo ◆　　ユーザー（${Def_Name}）の設定を中断します。
            echo ◆　　ユーザー（${Def_Name}）のルーティングプロファイルの更新でエラーが発生しました。（RC=${RC}）>>${OUTPUT_FILE1}
            echo ◆　　ユーザー（${Def_Name}）の設定を中断します。>>${OUTPUT_FILE1}
            exit 10
          else
            echo ◇　　ユーザー（${Def_Name}）のルーティングプロファイルの更新が完了しました。
          fi        
          
          #######################################
          # セキュリティプロファイル
          #######################################
          aws --region ${Target_Region} connect update-user-security-profiles  \
             --user-id ${ID_User}   \
             --security-profile-id ${ID_security_profiles}   \
             --instance-id ${ID_AmazonConnect}   \
             --output text
          RC=$?
          if [ ${RC} -ne 0 ] ; then
            echo ◆　　ユーザー（${Def_Name}）のセキュリティプロファイルの更新でエラーが発生しました。（RC=${RC}）
            echo ◆　　ユーザー（${Def_Name}）の設定を中断します。
            echo ◆　　ユーザー（${Def_Name}）のセキュリティプロファイルの更新でエラーが発生しました。（RC=${RC}）>>${OUTPUT_FILE1}
            echo ◆　　ユーザー（${Def_Name}）の設定を中断します。>>${OUTPUT_FILE1}
            exit 10
          else
            echo ◇　　ユーザー（${Def_Name}）のセキュリティプロファイルの更新が完了しました。
          fi        
          
          #######################################
          # エージェント階層
          #######################################
          aws --region ${Target_Region} connect update-user-hierarchy  \
             --user-id ${ID_User}   \
             ${C_hierarchy_group_id}  \
             --instance-id ${ID_AmazonConnect}   \
             --output text
          RC=$?
          if [ ${RC} -ne 0 ] ; then
            echo ◆　　ユーザー（${Def_Name}）のエージェント階層の更新でエラーが発生しました。（RC=${RC}）
            echo ◆　　ユーザー（${Def_Name}）の設定を中断します。
            echo ◆　　ユーザー（${Def_Name}）のエージェント階層の更新でエラーが発生しました。（RC=${RC}）>>${OUTPUT_FILE1}
            echo ◆　　ユーザー（${Def_Name}）の設定を中断します。>>${OUTPUT_FILE1}
            exit 10
          else
            echo ◇　　ユーザー（${Def_Name}）のエージェント階層の更新が完了しました。
          fi        
        fi
        
        ###############################################################################
        # クイック接続の設定
        ###############################################################################
        if [ "${Def_Q_Connect_Name}" != "" -a "${Def_Q_Connect_Flow}" != "" ] ; then
          
          # 問い合わせフローからIDを取得
          ID_Flow=`aws --region ${Target_Region} connect list-contact-flows  --instance-id  ${ID_AmazonConnect}   --output  text | \
                                          grep  $'\t'"${Def_Q_Connect_Flow}"$  |  sed -e "s/^[^\t]*\t[^\t]*\t[^\t]*\t[^\t]*\t\([^\t]*\)\t.*$/\1/"`
          RC=$?
          if [ ${RC} -ne 0 ] ; then
            echo ◆　　ユーザー（${Def_Name}）のクイック接続（${Def_Q_Connect_Name}）の問い合わせフロー（${Def_Q_Connect_Flow}）の情報取得でエラーが発生しました。（RC=${RC}）
            echo ◆　　ユーザー（${Def_Name}）の設定を中断します。
            echo ◆　　ユーザー（${Def_Name}）のクイック接続（${Def_Q_Connect_Name}）の問い合わせフロー（${Def_Q_Connect_Flow}）の情報取得でエラーが発生しました。（RC=${RC}）>>${OUTPUT_FILE1}
            echo ◆　　ユーザー（${Def_Name}）の設定を中断します。>>${OUTPUT_FILE1}
            exit 10
          fi
          if [ "${ID_Flow}" = "" ] ;then
            echo ◆　　ユーザー（${Def_Name}）のクイック接続（${Def_Q_Connect_Name}）の問い合わせフロー（${Def_Q_Connect_Flow}）の情報が取得できませんでした。
            echo ◆　　ユーザー（${Def_Name}）の設定を中断します。
            echo ◆　　ユーザー（${Def_Name}）のクイック接続（${Def_Q_Connect_Name}）の問い合わせフロー（${Def_Q_Connect_Flow}）の情報が取得できませんでした。>>${OUTPUT_FILE1}
            echo ◆　　ユーザー（${Def_Name}）の設定を中断します。>>${OUTPUT_FILE1}
            exit 10
          fi
          
          # ユーザー名からIDを取得
#          ID_Send=`aws --region ${Target_Region} connect list-users  --instance-id  ${ID_AmazonConnect}  --output text | grep $'\t'"${Def_Name}$" | sed -e "s/^[^\t]*\t[^\t]*\t\([^\t]*\)\t.*$/\1/"`
          ID_Send=`cat ${Work_List} | grep $'\t'"${Def_Name}$" | sed -e "s/^[^\t]*\t[^\t]*\t\([^\t]*\)\t.*$/\1/"`
          RC=$?
          if [ ${RC} -ne 0 ] ; then
            echo ◆　　ユーザー（${Def_Name}）のID取得でエラーが発生しました。（RC=${RC}）
            echo ◆　　ユーザー（${Def_Name}）の設定を中断します。
            echo ◆　　ユーザー（${Def_Name}）のID取得でエラーが発生しました。（RC=${RC}）>>${OUTPUT_FILE1}
            echo ◆　　ユーザー（${Def_Name}）の設定を中断します。>>${OUTPUT_FILE1}
            exit 10
          fi
          if [ "${ID_Send}" = "" ] ; then
            echo ◆　　　ユーザー（${Def_Name}）のIDを取得できませんでした。
            echo ◆　　　ユーザー（${Def_Name}）の設定を中断します。
            echo ◆　　　ユーザー（${Def_Name}）のIDを取得できませんでした。>>${OUTPUT_FILE1}
            echo ◆　　　ユーザー（${Def_Name}）の設定を中断します。>>${OUTPUT_FILE1}
            exit 10
          fi
         
          # クイック接続の重複確認
          aws --region ${Target_Region} connect list-quick-connects  --instance-id  ${ID_AmazonConnect} --output json | \
                                           jq -r .QuickConnectSummaryList[].Name | grep  "^${Def_Q_Connect_Name}$" >/dev/null 2>&1
          RC=$?
          if [ ${RC} -eq 0 ] ; then
            # クイック接続が存在する
            
            # クイック接続のID取得
            ID_quick_connect=`aws --region ${Target_Region} connect list-quick-connects  --instance-id  ${ID_AmazonConnect} --output text | \
                                          grep  $'\t'"${Def_Q_Connect_Name}"$'\t' | sed -e "s/^[^\t]*\t[^\t]*\t\([^\t]*\)\t[^\t]*\t.*$/\1/"`
            RC=$?
            if [ ${RC} -ne 0 ] ; then
              echo ◆　　ユーザー（${Def_Name}）のクイック接続（${Def_Q_Connect_Name}）のID取得でエラーが発生しました。（RC=${RC}）
              echo ◆　　ユーザー（${Def_Name}）の設定を中断します。
              echo ◆　　ユーザー（${Def_Name}）のクイック接続（${Def_Q_Connect_Name}）のID取得でエラーが発生しました。（RC=${RC}）>>${OUTPUT_FILE1}
              echo ◆　　ユーザー（${Def_Name}）の設定を中断します。>>${OUTPUT_FILE1}
              exit 10
            fi
            if [ "${ID_quick_connect}" = "" ] ; then
              echo ◆　　ユーザー（${Def_Name}）クイック接続（${Def_Q_Connect_Name}）のID取得が取得できませんでした。
              echo ◆　　ユーザー（${Def_Name}）の設定を中断します。
              echo ◆　　ユーザー（${Def_Name}）クイック接続（${Def_Q_Connect_Name}）のID取得が取得できませんでした。>>${OUTPUT_FILE1}
              echo ◆　　ユーザー（${Def_Name}）の設定を中断します。>>${OUTPUT_FILE1}
              exit 10
            fi
            
            aws --region ${Target_Region} connect update-quick-connect-config --instance-id ${ID_AmazonConnect} \
                        --quick-connect-config  "QuickConnectType=USER,UserConfig={UserId=${ID_Send},ContactFlowId=${ID_Flow}}" \
                        --quick-connect-id  ${ID_quick_connect}  --output text
            RC=$?
            if [ ${RC} -eq 0 ] ; then
              echo ◇　　ユーザー（${Def_Name}）のクイック接続（${Def_Q_Connect_Name}）の更新に成功しました。
            else
              echo ◆　　ユーザー（${Def_Name}）のクイック接続（${Def_Q_Connect_Name}）の更新でエラーが発生しました。（RC=${RC}）
              echo ◆　　ユーザー（${Def_Name}）の設定を中断します。
              echo ◆　　ユーザー（${Def_Name}）のクイック接続（${Def_Q_Connect_Name}）の更新でエラーが発生しました。（RC=${RC}）>>${OUTPUT_FILE1}
              echo ◆　　ユーザー（${Def_Name}）の設定を中断します。>>${OUTPUT_FILE1}
              exit 10
            fi
            
          else
            # クイック接続が存在しない
            aws --region ${Target_Region} connect create-quick-connect --instance-id ${ID_AmazonConnect} --name ${Def_Q_Connect_Name}  \
                                             --quick-connect-config  "QuickConnectType=USER,UserConfig={UserId=${ID_Send},ContactFlowId=${ID_Flow}}" \
                                             --output text >/dev/null 2>&1
            RC=$?
            if [ ${RC} -eq 0 ] ; then
              echo ◇　　ユーザー（${Def_Name}）のクイック接続（${Def_Q_Connect_Name}）の新規登録に成功しました。
            else
              echo ◆　　ユーザー（${Def_Name}）のクイック接続（${Def_Q_Connect_Name}）の新規登録でエラーが発生しました。（RC=${RC}）
              echo ◆　　ユーザー（${Def_Name}）の設定を中断します。
              echo ◆　　ユーザー（${Def_Name}）のクイック接続（${Def_Q_Connect_Name}）の新規登録でエラーが発生しました。（RC=${RC}）>>${OUTPUT_FILE1}
              echo ◆　　ユーザー（${Def_Name}）の設定を中断します。>>${OUTPUT_FILE1}
              exit 10
            fi
          fi
        fi
      else
        # Def_Need が「必要」以外の場合、該当ユーザーを削除
        
        ###############################################################################
        # クイック接続の設定
        ###############################################################################
        if [ "${Def_Q_Connect_Name}" != "" ] ; then
          
          # クイック接続の重複確認
          aws --region ${Target_Region} connect list-quick-connects  --instance-id  ${ID_AmazonConnect} --output json | \
                                           jq -r .QuickConnectSummaryList[].Name | grep  "^${Def_Q_Connect_Name}$" >/dev/null 2>&1
          RC=$?
          if [ ${RC} -eq 0 ] ; then
            # クイック接続が存在する
            echo ◇　　ユーザー（${Def_Name}）のクイック接続（${Def_Q_Connect_Name}）を削除します。
            
            # クイック接続のID取得
            ID_quick_connect=`aws --region ${Target_Region} connect list-quick-connects  --instance-id  ${ID_AmazonConnect} --output text | \
                                          grep  $'\t'"${Def_Q_Connect_Name}"$'\t' | sed -e "s/^[^\t]*\t[^\t]*\t\([^\t]*\)\t[^\t]*\t.*$/\1/"`
            RC=$?
            if [ ${RC} -ne 0 ] ; then
              echo ◆　　ユーザー（${Def_Name}）のクイック接続（${Def_Q_Connect_Name}）のID取得でエラーが発生しました。（RC=${RC}）
              echo ◆　　ユーザー（${Def_Name}）の設定を中断します。
              echo ◆　　ユーザー（${Def_Name}）のクイック接続（${Def_Q_Connect_Name}）のID取得でエラーが発生しました。（RC=${RC}）>>${OUTPUT_FILE1}
              echo ◆　　ユーザー（${Def_Name}）の設定を中断します。>>${OUTPUT_FILE1}
              exit 10
            fi
            if [ "${ID_quick_connect}" = "" ] ; then
              echo ◆　　ユーザー（${Def_Name}）クイック接続（${Def_Q_Connect_Name}）のID取得が取得できませんでした。
              echo ◆　　ユーザー（${Def_Name}）の設定を中断します。
              echo ◆　　ユーザー（${Def_Name}）クイック接続（${Def_Q_Connect_Name}）のID取得が取得できませんでした。>>${OUTPUT_FILE1}
              echo ◆　　ユーザー（${Def_Name}）の設定を中断します。>>${OUTPUT_FILE1}
              exit 10
            fi
            
            aws --region ${Target_Region} connect delete-quick-connect --instance-id ${ID_AmazonConnect} \
                        --quick-connect-id  ${ID_quick_connect}  --output text
            RC=$?
            if [ ${RC} -eq 0 ] ; then
              echo ◇　　ユーザー（${Def_Name}）のクイック接続（${Def_Q_Connect_Name}）の削除に成功しました。
            else
              echo ◆　　ユーザー（${Def_Name}）のクイック接続（${Def_Q_Connect_Name}）の削除でエラーが発生しました。（RC=${RC}）
              echo ◆　　ユーザー（${Def_Name}）の設定を中断します。
              echo ◆　　ユーザー（${Def_Name}）のクイック接続（${Def_Q_Connect_Name}）の削除でエラーが発生しました。（RC=${RC}）>>${OUTPUT_FILE1}
              echo ◆　　ユーザー（${Def_Name}）の設定を中断します。>>${OUTPUT_FILE1}
              exit 10
            fi
            
          else
            # クイック接続が存在しない
            echo ◇　　ユーザー（${Def_Name}）のクイック接続（${Def_Q_Connect_Name}）のは存在しません。（削除済み）
          fi
        fi
        
        ###############################################################################
        # ユーザーの削除
        ###############################################################################
        
        # ユーザー有無チェック
#        aws --region ${Target_Region} connect list-users --instance-id ${ID_AmazonConnect} --output json | jq -r .UserSummaryList[].Username  | grep  "^${Def_Name}$" >/dev/null 2>&1
        cat ${Work_List} | grep  $'\t'"${Def_Name}"$ >/dev/null 2>&1
        RC=$?
        if [ ${RC} -ne 0 ] ; then
          # ユーザー無し
          if [ "${Def_Name}" != "" ] ;then
            echo ◇　　ユーザー（${Def_Name}）は存在しません。（削除済み）
          fi
        else
          # ユーザーあり
          echo ◇　　ユーザー（${Def_Name}）を削除します。
          
          # ユーザーID取得
#          ID_User=`aws --region ${Target_Region} connect list-users  --instance-id  ${ID_AmazonConnect} --output text | grep $'\t'"${Def_Name}$" | sed -e "s/^[^\t]*\t[^\t]*\t\([^\t]*\)\t.*$/\1/"`
          ID_User=`cat ${Work_List} | grep $'\t'"${Def_Name}$" | sed -e "s/^[^\t]*\t[^\t]*\t\([^\t]*\)\t.*$/\1/"`
          RC=$?
          if [ ${RC} -ne 0 ] ; then
            echo ◆　　ユーザー（${Def_Name}）のID取得でエラーが発生しました。（RC=${RC}）
            echo ◆　　ユーザー（${Def_Name}）の設定を中断します。
            echo ◆　　ユーザー（${Def_Name}）のID取得でエラーが発生しました。（RC=${RC}）>>${OUTPUT_FILE1}
            echo ◆　　ユーザー（${Def_Name}）の設定を中断します。>>${OUTPUT_FILE1}
            exit 10
          fi
          
          # ユーザー削除
          aws --region ${Target_Region} connect delete-user  \
             --user-id ${ID_User}  \
             --instance-id ${ID_AmazonConnect}   \
             --output text
          RC=$?
          if [ ${RC} -ne 0 ] ; then
            echo ◆　　ユーザー（${Def_Name}）の削除でエラーが発生しました。（RC=${RC}）
            echo ◆　　ユーザー（${Def_Name}）の設定を中断します。
            echo ◆　　ユーザー（${Def_Name}）の削除でエラーが発生しました。（RC=${RC}）>>${OUTPUT_FILE1}
            echo ◆　　ユーザー（${Def_Name}）の設定を中断します。>>${OUTPUT_FILE1}
            exit 10
          else
            echo ◇　　ユーザー（${Def_Name}）の削除が完了しました。
            echo ◇　　ユーザー一覧からユーザー（${Def_Name}）を削除します。
            sed /$'\t'${Def_Name}$/d  ${Work_List} > ${Work_Data1}
            cat ${Work_Data1} > ${Work_List}
            rm -f ${Work_Data1}
          fi
        fi
        
      fi
      echo ◇　対象ユーザー（${Def_Name}）の処理を終了します。（${User_CNT}件目）
      echo ◇　対象ユーザー（${Def_Name}）の処理を終了します。（${User_CNT}件目）>>${OUTPUT_FILE1}
    else
      echo ◇
      echo ◇　コメント行をスキップします。（${User_CNT}件目）
      echo ◇　コメント行をスキップします。（${User_CNT}件目）>>${OUTPUT_FILE1}
    fi
    
    
    ############################################
    # ユーザーデータを処理済みファイルへ書き込み
    ############################################
    echo ${line} >>${OUTPUT_FILE5}
    
    ############################################
    # カウンターファイル更新
    ############################################
    echo User_CNT=${User_CNT}> ${OUTPUT_FILE4}
    echo Max_CNT=${Max_CNT}>> ${OUTPUT_FILE4}
    echo User_START_TIME=\"${User_START_TIME}\">> ${OUTPUT_FILE4}
    
    ############################################
    # ユーザー一覧から1行削除処理
    ############################################
    sed -e '1d' ${OUTPUT_FILE3} > ${Work_UsersList}
    cp -p ${Work_UsersList} ${OUTPUT_FILE3}
    rm -f ${Work_UsersList}
    
  done
#  done < ./${File_users_list}
  echo ◇
  echo ◇　ユーザーの設定を終了しました。
  echo ◇
else
  echo ◇
  echo ◇　ユーザー設定ファイルが定義されていない為、中断します。
  echo ◇
fi

rm -f ${Work_List}
rm -f ${OUTPUT_FILE3}
rm -f ${OUTPUT_FILE4}
User_END_TIME=`TZ=JST-9 date +"%Y/%m/%d %H:%M:%S"`



echo ◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇
echo ◇
echo ◇　Amazon Connect環境ユーザー設定（ユーザー管理）が完了しました。
echo ◇
echo ◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇
echo ◇
echo ◇　ユーザー設定処理
echo ◇　　処理レコード数： ${User_CNT} 件
echo ◇　　総レコード数　： ${Max_CNT} 件
echo ◇　　処理時間　　　： ${User_START_TIME} ～ ${User_END_TIME}
echo ◇
echo ◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇

echo ◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇ >>${OUTPUT_FILE1}
echo ◇ >>${OUTPUT_FILE1}
echo ◇　ユーザー設定処理 >>${OUTPUT_FILE1}
echo ◇　　処理レコード数： ${User_CNT} 件 >>${OUTPUT_FILE1}
echo ◇　　総レコード数　： ${Max_CNT} 件 >>${OUTPUT_FILE1}
echo ◇　　処理時間　　　： ${User_START_TIME} ～ ${User_END_TIME} >>${OUTPUT_FILE1}
echo ◇ >>${OUTPUT_FILE1}
echo ◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇ >>${OUTPUT_FILE1}

unset AWS_MAX_ATTEMPTS
exit 0

