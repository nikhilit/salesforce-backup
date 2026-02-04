/**
* @File Name : AS_RazorPayStatusReqWrapper.cls
* @Description :
* @Author :
* @Last Modified By :
* @Last Modified On : July 10, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | July 10, 2025 |   | Initial Version
**/
public class AS_RazorPayStatusReqWrapper {
    public String username;
    public String appKey;
    public String origP2pRequestId;

    public AS_RazorPayStatusReqWrapper(String username, String appKey, String p2pId) {
        this.username = username;
        this.appKey = appKey;
        this.origP2pRequestId = p2pId;
    }
}