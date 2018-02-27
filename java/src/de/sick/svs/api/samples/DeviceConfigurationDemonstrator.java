/**
 * Copyright note: Redistribution and use in source, with or without modification, are permitted.
 * 
 * Created: March 2016;
 *
 * @author: Uwe Hahne SICK AG, Waldkirch email: techsupport0905@sick.de Last commit: $Date: 2015-01-21 13:56:28 +0100 (Mi,
 *          21 Jan 2015) $ Last editor: $Author: hahneuw $
 *
 *          Version "$Revision: 8900 $"
 *
 */
package de.sick.svs.api.samples;

import java.util.Locale;

import de.sick.svs.api.DeviceConfigurationFactory;
import de.sick.svs.api.DeviceFactory;
import de.sick.svs.api.IDevice;
import de.sick.svs.api.IDeviceConfiguration;
import de.sick.svs.api.geometry.IVector3f;
import de.sick.svs.api.internal.geometry.Vector3f;

/**
 * Demonstrator class for device configuration
 *
 */
public class DeviceConfigurationDemonstrator
{
    /**
     * Demonstrates how to read and write the device configuration parameters.
     */
    static void runDemo(String ipAddress, String filename)
    {
        System.out.print("Init device...");
        IDevice device = DeviceFactory.obtainDevice(ipAddress, filename);
        System.out.println("done.");

        System.out.print("Trying to connect...");
        device.connect();

        if (device.isConnected())
        {
            System.out.println("done.");
            // obtain device configuration object
            IDeviceConfiguration deviceConfig = DeviceConfigurationFactory.obtainDeviceConfiguration(device);

            // get device position and orientation
            IVector3f devicePosition = deviceConfig.readDevicePosition();
            IVector3f deviceOrientation = deviceConfig.readDeviceOrientation();

            System.out.format(Locale.ENGLISH, "Device position: x:%.3f, y:%.3f, z:%.3f%n", devicePosition.x(),
                devicePosition.y(), devicePosition.z());
            System.out.format(Locale.ENGLISH, "Device orientation: x:%.3f, y:%.3f, z:%.3f%n", deviceOrientation.x(),
                deviceOrientation.y(), deviceOrientation.z());

            // change device configurations

            // login first
            device.login(3, "CLIENT");
            // setting the device position to x=1m, y=1m, z=2m in world coordinates.
            deviceConfig.setDevicePosition(Vector3f.xyz(1000, 1000, 2000));

            // rotating the device by 90 degrees around the Z-axis.
            deviceConfig.setDeviceOrientation(Vector3f.xyz(0, 0, 90));

            IVector3f devicePositionNew = deviceConfig.readDevicePosition();
            IVector3f deviceOrientationNew = deviceConfig.readDeviceOrientation();

            System.out.format(Locale.ENGLISH, "New device position: x:%.3f, y:%.3f, z:%.3f%n", devicePositionNew.x(),
                devicePositionNew.y(), devicePositionNew.z());
            System.out.format(Locale.ENGLISH, "New device orientation: x:%.3f, y:%.3f, z:%.3f%n",
                deviceOrientationNew.x(), deviceOrientationNew.y(), deviceOrientationNew.z());

            // reset to startup values
            deviceConfig.setDevicePosition(devicePosition);
            deviceConfig.setDeviceOrientation(deviceOrientation);

            // logout afterwards
            device.logout();

            // Disconnect device
            device.disconnect();
        }
        else
        {
            System.out.println("Failed to connect.");
        }
    }
}
