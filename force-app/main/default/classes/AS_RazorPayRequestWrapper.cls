/**
* @File Name : AS_RazorPayRequestWrapper.cls
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

public class AS_RazorPayRequestWrapper {
	public String username;
	public String appKey;
	public String amount;
	public String customerMobileNumber;
	public String externalRefNumber;
	public String externalRefNumber2;
	public String externalRefNumber3;
	public String externalRefNumber4;
	public String mode;
	public PushTo pushTo;

	public class PushTo {
		public String deviceId;
		public PushTo(String deviceId) {
			this.deviceId = deviceId;
		}
	}
}