/**
 * Growl.java
 * 
 * Version:
 * $Id:$
 *
 * Revisions:
 * $Log:$
 *
 */

package com.growl;

import com.apple.cocoa.foundation.NSDistributedNotificationCenter;
import com.apple.cocoa.foundation.NSArray;
import com.apple.cocoa.foundation.NSDictionary;
import com.apple.cocoa.foundation.NSMutableDictionary;
import com.apple.cocoa.foundation.NSData;
import com.apple.cocoa.application.NSImage;

/**
 * A class that encapsulates the "work" of talking to growl
 *
 * @author Karl Adam
 */
public class Growl {

	// defines
	/** The name of the growl registration notification for DNC. */
	public static final String GROWL_APP_REGISTRATION = "GrowlApplicationRegistrationNotification";

	//  Ticket Defines
	/** Ticket key for the application name. */
	public static final String GROWL_APP_NAME = "ApplicationName";
	/** Ticket key for the application icon. */
	public static final String GROWL_APP_ICON = "ApplicationIcon";
	/** Ticket key for the default notifactions. */
	public static final String GROWL_NOTIFICATIONS_DEFAULT = "DefaultNotifications";
	/** Ticket key for all notifactions. */
	public static final String GROWL_NOTIFICATIONS_ALL = "AllNotifications";

	//  Notification Defines
	/** The name of the growl notification for DNC. */
	public static final String GROWL_NOTIFICATION = "GrowlNotification";
	/** Notification key for the name. */
	public static final String GROWL_NOTIFICATION_NAME = "NotificationName";
	/** Notification key for the title. */
	public static final String GROWL_NOTIFICATION_TITLE = "NotificationTitle";
	/** Notification key for the description. */
	public static final String GROWL_NOTIFICATION_DESCRIPTION = "NotificationDescription";
	/** Notification key for the icon. */
	public static final String GROWL_NOTIFICATION_ICON = "NotificationIcon";
	/** Notification key for the application icon. */
	public static final String GROWL_NOTIFICATION_APP_ICON = "NotificationAppIcon";
	/** Notification key for the sticky flag. */
	public static final String GROWL_NOTIFICATION_STICKY = "NotificationSticky";
	/** Notification key for the identifier. */
	public static final String GROWL_NOTIFICATION_IDENTIFIER = "GrowlNotificationIdentifier";

	// Actual instance data
	private boolean      registered;    // We should only register once
	private String       appName;       // "Application" Name
	private NSData       appImageData;  // "application" Icon
	private NSDictionary regDict;       // Registration Dictionary
	private NSArray      allNotes;      // All notifications
	private NSArray      defNotes;      // Default Notifications
	private NSDistributedNotificationCenter theCenter;

	//************  Constructors **************//

	/**
	 * Convenience method to contruct a growl instance, defers to Growl(String 
	 * inAppName, NSData inImageData, NSArray inAllNotes, NSArray inDefNotes, 
	 * boolean registerNow) with empty arrays for your notifications.
	 *
	 *
	 * @param inAppName - The Name of your "application"
	 * @param inImage - The NSImage Icon for your Application
	 *
	 */
	public Growl(String inAppName, NSImage inImage) {
	
		this(inAppName,
			  inImage.TIFFRepresentation(),
			  new NSArray(),
			  new NSArray(),
			  false);
	}

	/**
	 * Convenience method to contruct a growl instance, defers to Growl(String 
	 * inAppName, NSData inImageData, NSArray inAllNotes, NSArray inDefNotes, 
	 * boolean registerNow) with empty arrays for your notifications.
	 *
	 * @param inAppName - The Name of your "Application"
	 * @param inImageData - The NSData for your NSImage
	 */
	public Growl(String inAppName, NSData inImageData) {

		this(inAppName,
			 inImageData,
			 new NSArray(),
			 new NSArray(),
			 false);
	}

	/**
	 * Convenience method to contruct a growl instance, defers to Growl(String 
	 * inAppName, NSData inImageData, NSArray inAllNotes, NSArray inDefNotes, 
	 * boolean registerNow) with empty arrays for your notifications.
	 * 
	 * @param inAppName - The Name of your "Application"
	 * @param inImagePath - The path to your icon
	 *
	 */
	public Growl(String inAppName, String inImagePath) {
	
		this(inAppName, 
			 new NSImage(inImagePath, false).TIFFRepresentation(), 
			 new NSArray(), 
			 new NSArray(), 
			 false);
	}

	/**
	 * Convenience method to contruct a growl instance, defers to Growl(String 
	 * inAppName, NSData inImageData, NSArray inAllNotes, NSArray inDefNotes, 
	 * boolean registerNow) with the arrays passed here and empty Data for the icon.
	 *
	 * @param inAppName - The Name of your "Application"
	 * @param inAllNotes - A String Array with the name of all your notifications
	 * @param inDefNotes - A String Array with the na,es of the Notifications on 
	 *                     by default
	 */
	public Growl(String inAppName, String [] inAllNotes, String [] inDefNotes) {

		this(inAppName, 
			 new NSData(), 
			 new NSArray(inAllNotes), 
			 new NSArray(inDefNotes), 
			 false);
	}

	/**
	 * Convenience method to contruct a growl instance, defers to Growl(String 
	 * inAppName, NSData inImageData, NSArray inAllNotes, NSArray inDefNotes, 
	 * boolean registerNow) with empty arrays for your notifications.
	 *
	 * @param inAppName - The Name of your "Application"
	 * @param inImageData - The Data of your "Application"'s icon
	 * @param inAllNotes - The NSArray of Strings of all your Notifications
	 * @param inDefNotes - The NSArray of Strings of your default Notifications
	 * @param registerNow - Since we have all the necessary info we can go ahead 
	 *                      and register
	 */
	public Growl(String inAppName, NSData inImageData, NSArray inAllNotes, 
	   NSArray inDefNotes, boolean registerNow) {
		appName = inAppName;
		appImageData = inImageData;
		allNotes = inAllNotes;
		defNotes = inDefNotes;

		theCenter  = (NSDistributedNotificationCenter)NSDistributedNotificationCenter.defaultCenter();

		if (registerNow) {
			register();
		}
	}

	//************  Commonly Used Methods **************//

	/**
	 * Register all our notifications with Growl, this should only be called
	 * once.
	 * @return <code>true</code>.
	 */
	public boolean register() {
		if (!registered) {

			// Construct our dictionary
			// Make the arrays of objects then keys
			Object [] objects = { appName, allNotes, defNotes, appImageData };
			String [] keys = { GROWL_APP_NAME, 
					GROWL_NOTIFICATIONS_ALL, 
					GROWL_NOTIFICATIONS_DEFAULT,
					GROWL_APP_ICON};

			// Make the Dictionary
			regDict = new NSDictionary(objects, keys);

			theCenter.postNotification(GROWL_APP_REGISTRATION,	// notificationName
									   (String)null,			// anObject
									   regDict,					// userInfoDictionary
									   true);					// deliverImmediately
		}

		return true;
	}

	/**
	 * The fun part is actually sending those notifications we worked so hard for
	 * so here we let growl know about things we think the user would like, and growl
	 * decides if that is the case.
	 *
	 * @param inNotificationName - The name of one of the notifications we told growl
	 *                             about.
	 * @param inIconData - The NSData for the icon for this notification, can be null
	 * @param inTitle - The Title of our Notification as Growl will show it
	 * @param inDescription - The Description of our Notification as Growl will 
	 *                        display it
	 * @param inExtraInfo - Growl is flexible and allows Display Plugins to do as they 
	 *                      please with thier own special keys and values, you may use 
	 *                      them here. These may be ignored by either the user's 
	 *                      preferences or the current Display Plugin. This can be null
	 * @param inSticky - Whether the Growl notification should be sticky
	 * @param inIdentifier - Notification identifier for coalescing. This can be null.
	 *
	 * @throws Exception When a notification is not known
	 */
	public void notifyGrowlOf(String inNotificationName, NSData inIconData, 
			       String inTitle, String inDescription, 
			       NSDictionary inExtraInfo, boolean inSticky,
				   String inIdentifier) throws Exception {
		NSMutableDictionary noteDict = new NSMutableDictionary();

		if (!allNotes.containsObject(inNotificationName)) {
			throw new Exception("Undefined Notification attempted");
		}

		noteDict.setObjectForKey(inNotificationName, GROWL_NOTIFICATION_NAME);
		noteDict.setObjectForKey(inTitle, GROWL_NOTIFICATION_TITLE);
		noteDict.setObjectForKey(inDescription, GROWL_NOTIFICATION_DESCRIPTION);
		noteDict.setObjectForKey(appName, GROWL_APP_NAME);
		if (inIconData != null) {
			noteDict.setObjectForKey(inIconData, GROWL_NOTIFICATION_ICON);
		}

		if (inSticky) {
			noteDict.setObjectForKey(new Integer(1), GROWL_NOTIFICATION_STICKY);
		}

		if (inIdentifier != null) {
			noteDict.setObjectForKey(inIdentifier, GROWL_NOTIFICATION_IDENTIFIER);
		}

		if (inExtraInfo != null) {
			noteDict.addEntriesFromDictionary(inExtraInfo);
		}

		theCenter.postNotification(GROWL_NOTIFICATION,
									(String)null,
									noteDict,
									true);
	}

	/**
	  * Convenience method that defers to notifyGrowlOf(String inNotificationName, 
	  * NSData inIconData, String inTitle, String inDescription, 
	  * NSDictionary inExtraInfo, boolean inSticky, String inIdentifier).
	  * This is primarily for compatibility with older code
	  *
	  * @param inNotificationName - The name of one of the notifications we told growl
	  *                             about.
	  * @param inIconData - The NSData for the icon for this notification, can be null
	  * @param inTitle - The Title of our Notification as Growl will show it
	  * @param inDescription - The Description of our Notification as Growl will 
	  *                        display it
	  * @param inExtraInfo - Growl is flexible and allows Display Plugins to do as
	  *                      they please with their own special keys and values, you
	  *                      may use them here. These may be ignored by either the
	  *                      user's  preferences or the current Display Plugin. This
	  *                      can be null.
	  * @param inSticky - Whether the Growl notification should be sticky.
	  *
	  * @throws Exception When a notification is not known
	  *
	  */
	public void notifyGrowlOf(String inNotificationName, NSData inIconData, 
			       String inTitle, String inDescription, 
			       NSDictionary inExtraInfo, boolean inSticky) throws Exception {
		notifyGrowlOf(inNotificationName, inIconData, inTitle, inDescription,
				inExtraInfo, inSticky, null);
	}


	/**
	  * Convenience method that defers to notifyGrowlOf(String inNotificationName, 
	  * NSData inIconData, String inTitle, String inDescription, 
	  * NSDictionary inExtraInfo, boolean inSticky, String inIdentifier).
	  * This is primarily for compatibility with older code
	  *
	  * @param inNotificationName - The name of one of the notifications we told growl
	  *                             about.
	  * @param inIconData - The NSData for the icon for this notification, can be null
	  * @param inTitle - The Title of our Notification as Growl will show it
	  * @param inDescription - The Description of our Notification as Growl will 
	  *                        display it
	  * @param inExtraInfo - Growl is flexible and allows Display Plugins to do as
	  *                      they please with their own special keys and values, you
	  *                      may use them here. These may be ignored by either the
	  *                      user's  preferences or the current Display Plugin. This
	  *                      can be null.
	  *
	  * @throws Exception When a notification is not known
	  *
	  */
	public void notifyGrowlOf(String inNotificationName, NSData inIconData, 
		                       String inTitle, String inDescription, 
		                       NSDictionary inExtraInfo) throws Exception {

		notifyGrowlOf(inNotificationName, inIconData, inTitle, inDescription,
			           inExtraInfo, false, null);
	}

	/**
	 * Convenienve method that defers to notifyGrowlOf(String inNotificationName, 
	 * NSData inIconData, String inTitle, String inDescription, 
	 * NSDictionary inExtraInfo, boolean inSticky, String inIdentifier) with
	 * <code>null</code> passed for icon, extraInfo and identifier arguments
	 *
	 * @param inNotificationName - The name of one of the notifications we told growl
	 *                             about.
	 * @param inTitle - The Title of our Notification as Growl will show it
	 * @param inDescription - The Description of our Notification as Growl will 
	 *                        display it
	 *
	 * @throws Exception When a notification is not known
	 */
	public void notifyGrowlOf(String inNotificationName, String inTitle, 
			       String inDescription) throws Exception {
		notifyGrowlOf(inNotificationName, (NSData)null, 
					   inTitle, inDescription, (NSDictionary)null, false, null);
	}

	/**
	  * Convenience method that defers to notifyGrowlOf(String inNotificationName, 
	  * NSData inIconData, String inTitle, String inDescription, 
	  * NSDictionary inExtraInfo, boolean inSticky)
	  * with <code>null</code> passed for icon and extraInfo arguments.
	  *
	  * @param inNotificationName - The name of one of the notifications we told growl
	  *                             about.
	  * @param inTitle - The Title of our Notification as Growl will show it
	  * @param inDescription - The Description of our Notification as Growl will 
	  *                        display it
	  * @param inSticky - Whether our notification should be sticky
	  *
	  * @throws Exception When a notification is not known
	  *
	  */
	public void notifyGrowlOf(String inNotificationName, String inTitle, 
							   String inDescription, boolean inSticky) throws Exception {
		notifyGrowlOf(inNotificationName, (NSData)null, 
					   inTitle, inDescription, (NSDictionary)null, inSticky, null);
	}

	/**
	 * Defers to notifyGrowlOf(String inNotificationName, NSData inIconData, 
	 * String inTitle, String inDescription, NSDictionary inExtraInfo,
	 * boolean inSticky, String inIdentifier) with <code>null</code> 
	 * passed for icon and extraInfo arguments.
	 *
	 * @param inNotificationName - The name of one of the notifications we told growl
	 *                             about.
	 * @param inImage - The notification image.
	 * @param inTitle - The Title of our Notification as Growl will show it
	 * @param inDescription - The Description of our Notification as Growl will 
	 *                        display it
	 * @param inExtraInfo - Look above for info
	 *
	 * @throws Exception When a notification is not known
	 *
	 */
	public void notifyGrowlOf(String inNotificationName, NSImage inImage, 
			       String inTitle, String inDescription, 
			       NSDictionary inExtraInfo) throws Exception {

		notifyGrowlOf(inNotificationName, inImage.TIFFRepresentation(),
					   inTitle, inDescription, inExtraInfo, false, null);
	}

	/**
	 * Convenienve method that defers to notifyGrowlOf(String inNotificationName, 
	 * NSData inIconData, String inTitle, String inDescription, 
	 * NSDictionary inExtraInfo, boolean inSticky, String inIdentifier) with
	 * <code>null</code> passed for extraInfo.
	 *
	 * @param inNotificationName - The name of one of the notifications we told growl
	 *                             about.
	 * @param inImagePath - Path to the image for this notification
	 * @param inTitle - The Title of our Notification as Growl will show it
	 * @param inDescription - The Description of our Notification as Growl will 
	 *                        display it
	 *
	 * @throws Exception When a notification is not known
	 */
	public void notifyGrowlOf(String inNotificationName, String inImagePath,
			       String inTitle, String inDescription) throws Exception {

		notifyGrowlOf(inNotificationName,
					  new NSImage(inImagePath, false).TIFFRepresentation(), 
					  inTitle, inDescription, (NSDictionary)null, false, null);
	}

	//************  Accessors **************//

	/**
	 * Accessor for The currently set "Application" Name
	 *
	 * @return String - Application Name
	 */
	public String applicationName() {
		return appName;
	}

	/**
	 * Accessor for the Array of allowed Notifications returned an NSArray
	 *
	 * @return the array of allowed notifications.
	 */
	public NSArray allowedNotifications() {
		return allNotes;
	}

	/**
	 * Accessor for the Array of default Notifications returned as an NSArray
	 *
	 * @return the array of default notifications.
	 */
	public NSArray defaultNotifications() {
		return defNotes;
	}

	//************  Mutators **************//

	/**
	 * Sets The name of the Application talking to growl
	 *
	 * @param inAppName - The Application Name
	 */
	public void setApplicationName(String inAppName) {
		appName = inAppName;
	}

	/**
	 * Set the list of allowed Notifications
	 *
	 * @param inAllNotes - The array of allowed Notifications
	 */
	public void setAllowedNotifications(NSArray inAllNotes) {
		allNotes = inAllNotes;
	}

	/**
	 * Set the list of allowed Notifications
	 *
	 * @param inAllNotes - The array of allowed Notifications
	 *
	 */
	public void setAllowedNotifications(String[] inAllNotes) {
		allNotes = new NSArray(inAllNotes);
	}

	/**
	 * Set the list of Default Notfiications
	 *
	 * @param inDefNotes - The default Notifications
	 *
	 * @throws Exception when an element of the array is not in the 
	 *                   allowedNotifications
	 */
	public void setDefaultNotifications(NSArray inDefNotes) throws Exception {
		int stop = inDefNotes.count();
		int i = 0;

		for(i = 0; i < stop; i++) {
			if (!allNotes.containsObject(inDefNotes.objectAtIndex(i))) {
				throw new Exception("Array Element not in Allowed Notifications");
			}
		} 

		defNotes = inDefNotes;
	}

	/**
	 * Set the list of Default Notfiications
	 *
	 * @param inDefNotes - The default Notifications
	 *
	 * @throws Exception when an element of the array is not in the 
	 *                   allowedNotifications
	 *
	 */
	public void setDefaultNotifications(String [] inDefNotes) throws Exception {
		int stop = inDefNotes.length;
		int i = 0;

		for(i = 0; i < stop; i++) {
			if (! allNotes.containsObject(inDefNotes[i])) {
				throw new Exception("Array Element not in Allowed Notifications");
			}
		} 

		defNotes = new NSArray(inDefNotes);
	}
}
