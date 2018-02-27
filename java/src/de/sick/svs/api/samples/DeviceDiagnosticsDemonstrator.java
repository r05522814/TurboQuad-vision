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

import de.sick.svs.api.DeviceDiagnosticsFactory;
import de.sick.svs.api.DeviceFactory;
import de.sick.svs.api.IDevice;
import de.sick.svs.api.IDeviceDiagnostics;
import de.sick.svs.api.diagnostics.IDeviceInformation;
import de.sick.svs.api.diagnostics.IDeviceStatus;
import de.sick.svs.api.diagnostics.IElectricalLimits;
import de.sick.svs.api.diagnostics.IElectricalMonitoring;
import de.sick.svs.api.diagnostics.IOperatingData;
import de.sick.svs.api.diagnostics.IServiceInformation;

/**
 * Demonstrator class for device diagnostics
 *
 */
public class DeviceDiagnosticsDemonstrator
{
    /**
     * Demonstrates how to read out the device diagnostics.
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
            IDeviceDiagnostics deviceDiagnostics = DeviceDiagnosticsFactory.obtainDeviceDiagnostics(device);

            // check device status
            IDeviceStatus deviceStatus = deviceDiagnostics.getDeviceStatus();
            showElectricalMonitoring(deviceStatus);

            showTemperatureLevel(deviceStatus);

            IOperatingData operatingData = deviceDiagnostics.getOperatingData();
            showDeviceInformation(operatingData);
            showServiceInformation(operatingData);

            System.out.print("Disconnecting...");
            // Disconnect device
            device.disconnect();
            if (!device.isConnected())
            {
                System.out.println("done.");
            }
        }
        else
        {
            System.out.println("Failed to connect.");
        }

    }

    /**
     * @param deviceStatus
     */
    private static void showTemperatureLevel(IDeviceStatus deviceStatus)
    {
        String temperatureLevel = deviceStatus.readTemperatureLevel();
        System.out.println("The current temperature level is " + temperatureLevel);
        System.out.print("The illumination is ");
        if (deviceStatus.readIfIlluminationIsActive())
        {
            System.out.println("active.");
        }
        else
        {
            System.out.println("not active.");
        }
    }

    /**
     * Prints the service information.
     *
     * @param operatingData The operating data object.
     */
    private static void showServiceInformation(
        IOperatingData operatingData)
    {
        IServiceInformation serviceInformation = operatingData.getServiceInformation();
        System.out.println("Number of power on cycles: " + serviceInformation.getNumberOfPowerOnCycles());
        System.out.println("Daily operating hours: " + serviceInformation.getDailyOperatingHours());
        float l_operatingHoursF = serviceInformation.getOperatingHours();
        int l_operatingMinutes = (int) ((l_operatingHoursF * 60) % 60);
        int l_operatingHours = (int) Math.floor(l_operatingHoursF);
        int l_operatingDays = (int) Math.floor(l_operatingHoursF / (24.0));
        l_operatingHours -= 24 * l_operatingDays;
        System.out.print("Operating time (since last service): ");
        if (l_operatingDays > 0)
        {
            System.out.print(l_operatingDays + " days - ");
        }
        if (l_operatingHours > 0)
        {
            System.out.print(l_operatingHours + " hours - ");
        }
        System.out.println(l_operatingMinutes + " minutes");
    }

    private static void showDeviceInformation(IOperatingData operatingData)
    {
        IDeviceInformation deviceInformation = operatingData.getDeviceInformation();
        System.out.println("Device identification: " + deviceInformation.getDeviceIdentName() + " - " +
            deviceInformation.getDeviceIdentVersion());
        System.out.println("Device type: " + deviceInformation.getDeviceType());
        System.out.println("Firmware version: " + deviceInformation.getFirmwareVersion());
        System.out.println("IO Controller version: " + deviceInformation.getIoControllerVersion());
        System.out.println("Manufacturer: " + deviceInformation.getManufacturer());
        System.out.println("Order number: " + deviceInformation.getOrderNumber());
        System.out.println("Serial nnumber: " + deviceInformation.getSerialNumber());
    }

    private static void showElectricalMonitoring(
        IDeviceStatus deviceStatus)
    {
        System.out.println("Checking the current at the illumination unit...");
        IElectricalLimits electricalLimits = deviceStatus.getElectricalLimits();
        float minAllowedLEDsCurrent = electricalLimits.getMinAllowedLEDsCurrent();
        float maxAllowedLEDsCurrent = electricalLimits.getMaxAllowedLEDsCurrent();
        System.out.println("The current should always be between " + String.format("%.2f", minAllowedLEDsCurrent) +
            " and " + String.format("%.2f", maxAllowedLEDsCurrent) + " Ampere.");

        IElectricalMonitoring electricalMonitoring = deviceStatus.getElectricalMonitoring();
        float currentLEDsCurrent = electricalMonitoring.getLEDsCurrent();
        System.out.println("The current is at the moment precisely " + currentLEDsCurrent + " Ampere.");
        try
        {
            Thread.sleep(1000L);
        }
        catch (InterruptedException e)
        {
            e.printStackTrace();
        }
        currentLEDsCurrent = electricalMonitoring.getLEDsCurrent();
        System.out.println("The current value is the same: " + currentLEDsCurrent +
            " Ampere. (because update() has not been called).");
        try
        {
            Thread.sleep(1000L);
        }
        catch (InterruptedException e)
        {
            e.printStackTrace();
        }
        electricalMonitoring.update();
        currentLEDsCurrent = electricalMonitoring.getLEDsCurrent();
        System.out.println("Now the current is updated correctly: " + currentLEDsCurrent + " Ampere.");

        System.out.println("Checking the operating voltage...");
        float minAllowedOpVoltage = electricalLimits.getMinAllowedOpVoltage();
        float maxAllowedOpVoltage = electricalLimits.getMaxAllowedOpVoltage();
        System.out.println("The operating voltage should always be between " +
            String.format("%.3f", minAllowedOpVoltage) + " and " + String.format("%.3f", maxAllowedOpVoltage) +
            " Volt.");
        float currentOpVoltage = electricalMonitoring.getOperatingVoltage();
        System.out.println("The operating voltage is at the moment at " + String.format("%.3f", currentOpVoltage) +
            " Volt.");
        float minOpVoltage = electricalMonitoring.getMinimalVoltage();
        float maxOpVoltage = electricalMonitoring.getMaximalVoltage();
        System.out.println("The operating voltage has always been between " + String.format("%.3f", minOpVoltage) +
            " and " + String.format("%.3f", maxOpVoltage) + " Volt.");
        try
        {
            Thread.sleep(1000L);
        }
        catch (InterruptedException e)
        {
            e.printStackTrace();
        }
        electricalMonitoring.update();
        currentOpVoltage = electricalMonitoring.getOperatingVoltage();
        System.out.println("The operating voltage is now precisely " + currentOpVoltage + " Volt.");
        try
        {
            Thread.sleep(1000L);
        }
        catch (InterruptedException e)
        {
            e.printStackTrace();
        }
        currentOpVoltage = electricalMonitoring.getOperatingVoltage();
        System.out.println("The current value is the same: " + currentOpVoltage +
            " Volt. (because update() has not been called).");
        try
        {
            Thread.sleep(1000L);
        }
        catch (InterruptedException e)
        {
            e.printStackTrace();
        }
        electricalMonitoring.update();
        currentOpVoltage = electricalMonitoring.getOperatingVoltage();
        System.out.println("Now the current is updated correctly: " + currentOpVoltage + " Volt.");
    }

}
