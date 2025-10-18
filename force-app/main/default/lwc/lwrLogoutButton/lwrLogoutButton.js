import { LightningElement, api } from "lwc";
import isGuest from "@salesforce/user/isGuest";
import basePath from "@salesforce/community/basePath";

export default class Logout extends LightningElement {
    /**
     * the display text for the logout button
     */
    @api logoutText;

    get isGuest() {
        return isGuest;
    }

    get logoutLink() {
        // site prefix is the community basePath without the trailing "/s"
        const sitePrefix = basePath.replace(/\/s$/i, "");
        return sitePrefix + "/secur/logout.jsp";
    }

    handleLogout() {
        // Preserve original behavior by navigating to the same logout URL
        window.location.href = this.logoutLink;
    }
}
