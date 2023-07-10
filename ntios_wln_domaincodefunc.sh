#!/bin/bash
#---FUNCTIONS
WLN_DomainSet() {
    #Input args
    local domain_enumval=${1}

    #Get country-code
    local isDomainSet=${PL_WLN_DOMAIN_TW}
    case "${domain_enumval}" in
        "${PL_WLN_DOMAIN_GR}")
            isDomainSet="${WLN_DOMAINCODE_GR}"
            ;;
        "${PL_WLN_DOMAIN_GU}")
            isDomainSet="${WLN_DOMAINCODE_GU}"
            ;;
        "${PL_WLN_DOMAIN_GT}")
            isDomainSet="${WLN_DOMAINCODE_GT}"
            ;;
        "${PL_WLN_DOMAIN_HT}")
            isDomainSet="${WLN_DOMAINCODE_HT}"
            ;;
        "${PL_WLN_DOMAIN_HN}")
            isDomainSet="${WLN_DOMAINCODE_HN}"
            ;;
        "${PL_WLN_DOMAIN_HK}")
            isDomainSet="${WLN_DOMAINCODE_HK}"
            ;;
        "${PL_WLN_DOMAIN_HU}")
            isDomainSet="${WLN_DOMAINCODE_HU}"
            ;;
        "${PL_WLN_DOMAIN_IS}")
            isDomainSet="${WLN_DOMAINCODE_IS}"
            ;;
        "${PL_WLN_DOMAIN_IN}")
            isDomainSet="${WLN_DOMAINCODE_IN}"
            ;;
        "${PL_WLN_DOMAIN_ID}")
            isDomainSet="${WLN_DOMAINCODE_ID}"
            ;;
        "${PL_WLN_DOMAIN_IE}")
            isDomainSet="${WLN_DOMAINCODE_IE}"
            ;;
        "${PL_WLN_DOMAIN_IL}")
            isDomainSet="${WLN_DOMAINCODE_IL}"
            ;;
        "${PL_WLN_DOMAIN_IT}")
            isDomainSet="${WLN_DOMAINCODE_IT}"
            ;;
        "${PL_WLN_DOMAIN_JP}")
            isDomainSet="${WLN_DOMAINCODE_JP}"
            ;;
        "${PL_WLN_DOMAIN_JO}")
            isDomainSet="${WLN_DOMAINCODE_JO}"
            ;;
        "${PL_WLN_DOMAIN_LV}")
            isDomainSet="${WLN_DOMAINCODE_LV}"
            ;;
        "${PL_WLN_DOMAIN_LI}")
            isDomainSet="${WLN_DOMAINCODE_LI}"
            ;;
        "${PL_WLN_DOMAIN_LT}")
            isDomainSet="${WLN_DOMAINCODE_LT}"
            ;;
        "${PL_WLN_DOMAIN_LU}")
            isDomainSet="${WLN_DOMAINCODE_LU}"
            ;;
        "${PL_WLN_DOMAIN_MY}")
            isDomainSet="${WLN_DOMAINCODE_MY}"
            ;;
        "${PL_WLN_DOMAIN_MT}")
            isDomainSet="${WLN_DOMAINCODE_MT}"
            ;;
        "${PL_WLN_DOMAIN_MA}")
            isDomainSet="${WLN_DOMAINCODE_MA}"
            ;;
        "${PL_WLN_DOMAIN_MX}")
            isDomainSet="${WLN_DOMAINCODE_MX}"
            ;;
        "${PL_WLN_DOMAIN_NL}")
            isDomainSet="${WLN_DOMAINCODE_NL}"
            ;;
        "${PL_WLN_DOMAIN_NZ}")
            isDomainSet="${WLN_DOMAINCODE_NZ}"
            ;;
        "${PL_WLN_DOMAIN_NO}")
            isDomainSet="${WLN_DOMAINCODE_NO}"
            ;;
        "${PL_WLN_DOMAIN_PE}")
            isDomainSet="${WLN_DOMAINCODE_PE}"
            ;;
        "${PL_WLN_DOMAIN_PT}")
            isDomainSet="${WLN_DOMAINCODE_PT}"
            ;;
        "${PL_WLN_DOMAIN_PL}")
            isDomainSet="${WLN_DOMAINCODE_PL}"
            ;;
        "${PL_WLN_DOMAIN_RO}")
            isDomainSet="${WLN_DOMAINCODE_RO}"
            ;;
        "${PL_WLN_DOMAIN_RU}")
            isDomainSet="${WLN_DOMAINCODE_RU}"
            ;;
        "${PL_WLN_DOMAIN_SA}")
            isDomainSet="${WLN_DOMAINCODE_SA}"
            ;;
        "${PL_WLN_DOMAIN_CS}")
            isDomainSet="${WLN_DOMAINCODE_CS}"
            ;;
        "${PL_WLN_DOMAIN_SG}")
            isDomainSet="${WLN_DOMAINCODE_SG}"
            ;;
        "${PL_WLN_DOMAIN_SK}")
            isDomainSet="${WLN_DOMAINCODE_SK}"
            ;;
        "${PL_WLN_DOMAIN_SI}")
            isDomainSet="${WLN_DOMAINCODE_SI}"
            ;;
        "${PL_WLN_DOMAIN_ZA}")
            isDomainSet="${WLN_DOMAINCODE_ZA}"
            ;;
        "${PL_WLN_DOMAIN_KR}")
            isDomainSet="${WLN_DOMAINCODE_KR}"
            ;;
        "${PL_WLN_DOMAIN_ES}")
            isDomainSet="${WLN_DOMAINCODE_ES}"
            ;;
        "${PL_WLN_DOMAIN_SE}")
            isDomainSet="${WLN_DOMAINCODE_SE}"
            ;;
        "${PL_WLN_DOMAIN_CH}")
            isDomainSet="${WLN_DOMAINCODE_CH}"
            ;;
        "${PL_WLN_DOMAIN_TW}")
            isDomainSet="${WLN_DOMAINCODE_TW}"
            ;;
        "${PL_WLN_DOMAIN_TR}")
            isDomainSet="${WLN_DOMAINCODE_TR}"
            ;;
        "${PL_WLN_DOMAIN_GB}")
            isDomainSet="${WLN_DOMAINCODE_GB}"
            ;;
        "${PL_WLN_DOMAIN_UA}")
            isDomainSet="${WLN_DOMAINCODE_UA}"
            ;;
        "${PL_WLN_DOMAIN_AE}")
            isDomainSet="${WLN_DOMAINCODE_AE}"
            ;;
        "${PL_WLN_DOMAIN_US}")
            isDomainSet="${WLN_DOMAINCODE_US}"
            ;;
        "${PL_WLN_DOMAIN_VE}")
            isDomainSet="${WLN_DOMAINCODE_VE}"
            ;;
    esac


    #Set country-code > get pid, wait for pid to finish, get exit-code
    sudo iw reg set "${isDomainSet}" >/dev/null;pid=$!;wait ${pid};exitcode=$?

    #Get country-code
    # shellcheck disable=SC2155
    local isDomainGet=$(IwDomainGet)

    #Print
    if [[ ${exitcode} -eq 0 ]]; then
        echo -e "${WLN_PRINTMSG_STATUS}: Set country-code (${WLN_LIGHTGREY}${isDomainSet}${WLN_RESETCOLOR}): ${WLN_PRINTMSG_DONE}"
    else
        echo -e "${WLN_PRINTMSG_STATUS}: Set country-code (${WLN_LIGHTGREY}${isDomainSet}${WLN_RESETCOLOR}): ${WLN_PRINTMSG_FAILED}"
        echo -e "${WLN_PRINTMSG_STATUS}: Current country-code (${WLN_LIGHTGREY}${isDomainGet}${WLN_RESETCOLOR})"
    fi
}
