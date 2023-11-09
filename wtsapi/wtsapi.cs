using System;
using System.Management.Automation;
using System.Runtime.InteropServices;

[assembly: System.Reflection.AssemblyVersion("1.0.0.0")]
[assembly: System.Reflection.AssemblyFileVersion("1.0.0.0")]

namespace Windows
{
   public static class Wtsapi32
   {
      [DllImport("wtsapi32.dll")]
      private static extern IntPtr WTSOpenServer(
         [MarshalAs(UnmanagedType.LPStr)] string pServerName
      );

      [DllImport("wtsapi32.dll")]
      private static extern void WTSCloseServer(
         IntPtr hServer
      );

      [DllImport("wtsapi32.dll")]
      private static extern Int32 WTSEnumerateSessions(
         IntPtr hServer,
         [MarshalAs(UnmanagedType.U4)] uint Reserved,
         [MarshalAs(UnmanagedType.U4)] uint Version,
         ref IntPtr ppSessionInfo,
         [MarshalAs(UnmanagedType.U4)] ref uint pCount
      );

      [DllImport("wtsapi32.dll")]
      private static extern void WTSFreeMemory(
         IntPtr pMemory
      );

      [DllImport("wtsapi32.dll")]
      private static extern bool WTSQuerySessionInformation(
         IntPtr hServer,
         uint sessionId,
         WTS_INFO_CLASS wtsInfoClass,
         out IntPtr ppBuffer,
         out uint pBytesReturned
      );

      [DllImport("wtsapi32.dll", SetLastError = true)]
      private static extern bool WTSLogoffSession(
         IntPtr hServer,
         uint SessionId,
         bool bWait
      );

      [StructLayout(LayoutKind.Sequential)]
      private struct WTS_SESSION_INFO
      {
         public uint SessionID;

         [MarshalAs(UnmanagedType.LPStr)]
         public string pWinStationName;

         public WTS_CONNECTSTATE_CLASS State;
      }

      [StructLayout(LayoutKind.Sequential)]
      private struct WTS_CLIENT_ADDRESS
      {
         public int AddressFamily;

         [MarshalAs(UnmanagedType.ByValArray, SizeConst=20)]
         public byte[] Address;
      }

      private enum WTS_CONNECTSTATE_CLASS
      {
         Active,
         Connected,
         ConnectQuery,
         Shadow,
         Disconnected,
         Idle,
         Listen,
         Reset,
         Down,
         Init
      }

      private enum ADDRESS_FAMILY
      {
         AF_UNSPEC = 0,
         AF_INET = 2,
         AF_IPX = 6,
         AF_NETBIOS = 17,
         AF_INET6 = 23
      }

      private enum WTS_INFO_CLASS
      {
         WTSInitialProgram,
         WTSApplicationName,
         WTSWorkingDirectory,
         WTSOEMId,
         WTSSessionId,
         WTSUserName,
         WTSWinStationName,
         WTSDomainName,
         WTSConnectState,
         WTSClientBuildNumber,
         WTSClientName,
         WTSClientDirectory,
         WTSClientProductId,
         WTSClientHardwareId,
         WTSClientAddress,
         WTSClientDisplay,
         WTSClientProtocolType,
         WTSIdleTime,
         WTSLogonTime,
         WTSIncomingBytes,
         WTSOutgoingBytes,
         WTSIncomingFrames,
         WTSOutgoingFrames,
         WTSClientInfo,
         WTSSessionInfo,
         WTSSessionInfoEx,
         WTSConfigInfo,
         WTSValidationInfo,
         WTSSessionAddressV4,
         WTSIsRemoteSession
      }

      public static void QuerySession(String ServerName = null, String UsernameQuery = null)
      {
         IntPtr ServerHandle = IntPtr.Zero;

         if (ServerName != null)
         {
            ServerHandle = WTSOpenServer(ServerName);
         }

         try
         {
            IntPtr SessionInfo = IntPtr.Zero;
            uint SessionCount = 0;
            Int32 retEnum = WTSEnumerateSessions(ServerHandle, 0, 1, ref SessionInfo, ref SessionCount);
            IntPtr CurrentSession = SessionInfo;

            if (retEnum != 0)
            {
               Int32 DataSize = Marshal.SizeOf(typeof(WTS_SESSION_INFO));
               IntPtr User = IntPtr.Zero;
               IntPtr Domain = IntPtr.Zero;
               IntPtr Client = IntPtr.Zero;
               //IntPtr Address = IntPtr.Zero;
               string Username = null;
               string LogonName = null;
               string ClientName = null;
               //string ClientAddress = null; // Doesn't work with RDG :(
               uint bytes = 0;

               Console.WriteLine(Environment.NewLine + ServerName);
               Console.WriteLine("SESSIONNAME".PadRight(32) + "USERNAME".PadRight(32)+ "ID".PadRight(8) + "STATE".PadRight(24) + "DEVICE".PadRight(24));
               for (int i = 0; i < SessionCount; i++)
               {
                  WTS_SESSION_INFO SI = (WTS_SESSION_INFO)Marshal.PtrToStructure((System.IntPtr)CurrentSession, typeof(WTS_SESSION_INFO));
                  CurrentSession += DataSize;

                  WTSQuerySessionInformation(ServerHandle, SI.SessionID, WTS_INFO_CLASS.WTSUserName, out User, out bytes);
                  WTSQuerySessionInformation(ServerHandle, SI.SessionID, WTS_INFO_CLASS.WTSDomainName, out Domain, out bytes);
                  WTSQuerySessionInformation(ServerHandle, SI.SessionID, WTS_INFO_CLASS.WTSClientName, out Client, out bytes);
                  //WTSQuerySessionInformation(ServerHandle, SI.SessionID, WTS_INFO_CLASS.WTSClientAddress, out Address, out bytes);
                  //WTS_CLIENT_ADDRESS CA = (WTS_CLIENT_ADDRESS)Marshal.PtrToStructure((System.IntPtr)Address, typeof(WTS_CLIENT_ADDRESS));

                  if (!(String.IsNullOrEmpty(Marshal.PtrToStringAnsi(User))))
                  {
                     Username = Marshal.PtrToStringAnsi(User);
                     LogonName = Marshal.PtrToStringAnsi(Domain) + "\\" + Marshal.PtrToStringAnsi(User);
                  }
                  else
                  {
                     Username = String.Empty;
                     LogonName = String.Empty;
                  }

                  if (!(String.IsNullOrEmpty(Marshal.PtrToStringAnsi(Client))))
                  {
                     ClientName = Marshal.PtrToStringAnsi(Client);
                  }
                  else
                  {
                     ClientName = String.Empty;
                  }

                  /* Doesn't work with RDGateway 😔
                  switch((ADDRESS_FAMILY)CA.AddressFamily)
                  {
                     case ADDRESS_FAMILY.AF_UNSPEC:
                        ClientAddress = String.Empty;
                        break;
                     case ADDRESS_FAMILY.AF_INET:
                        ClientAddress = String.Format("{0}.{1}.{2}.{3}", CA.Address[2], CA.Address[3], CA.Address[4], CA.Address[5]);
                        break;
                     case ADDRESS_FAMILY.AF_INET6:
                        byte[] IPv6 = new byte[16];
                        Array.Copy(CA.Address, 0, IPv6, 0, 16); // ATTENTION: Microsoft does not document WHERE the 16 bytes of the IPv6 address are located in the 20 byte array (IPv4 starts at byte 2, not 0)!
                        ClientAddress = BitConverter.ToString(IPv6);
                        break;
                     default:
                        ClientAddress = BitConverter.ToString(CA.Address);
                        break;
                  }
                  */

                  if (!(String.IsNullOrEmpty(UsernameQuery)))
                  {
                     WildcardPattern pattern = new WildcardPattern(UsernameQuery.ToLower());
                     if (pattern.IsMatch(Username.ToLower()))
                     {
                        Console.WriteLine(SI.pWinStationName.PadRight(32) + LogonName.PadRight(32) + SI.SessionID.ToString().PadRight(8) + SI.State.ToString().PadRight(24) + ClientName.PadRight(24));
                     }
                  }
                  else
                  {
                     Console.WriteLine(SI.pWinStationName.PadRight(32) + LogonName.PadRight(32) + SI.SessionID.ToString().PadRight(8) + SI.State.ToString().PadRight(24) + ClientName.PadRight(24));
                  }

                  WTSFreeMemory(User); 
                  WTSFreeMemory(Domain);
                  WTSFreeMemory(Client);
                  //WTSFreeMemory(Address);
               }

               WTSFreeMemory(SessionInfo);
            }
         }
         finally
         {
            WTSCloseServer(ServerHandle);
         }
      }

      public static void LogoffSession(String ServerName, String Username)
      {
         IntPtr ServerHandle = IntPtr.Zero;

         if (ServerName != null)
         {
            ServerHandle = WTSOpenServer(ServerName);
         }

         try
         {
            IntPtr SessionInfo = IntPtr.Zero;
            uint SessionCount = 0;
            Int32 retEnum = WTSEnumerateSessions(ServerHandle, 0, 1, ref SessionInfo, ref SessionCount);
            IntPtr CurrentSession = SessionInfo;

            if (retEnum != 0)
            {
               Int32 DataSize = Marshal.SizeOf(typeof(WTS_SESSION_INFO));
               IntPtr User = IntPtr.Zero;
               uint bytes = 0;

               for (int i = 0; i < SessionCount; i++)
               {
                  WTS_SESSION_INFO SI = (WTS_SESSION_INFO)Marshal.PtrToStructure((System.IntPtr)CurrentSession, typeof(WTS_SESSION_INFO));
                  CurrentSession += DataSize;

                  WTSQuerySessionInformation(ServerHandle, SI.SessionID, WTS_INFO_CLASS.WTSUserName, out User, out bytes);

                  if (String.Equals(Marshal.PtrToStringAnsi(User), Username, StringComparison.OrdinalIgnoreCase))
                  {
                     bool retLogoff = WTSLogoffSession(ServerHandle, SI.SessionID, true);

                     if (retLogoff == true)
                     {
                        Console.WriteLine(ServerName + ": Logoff of session " + SI.SessionID + ":" + Marshal.PtrToStringAnsi(User) + " successful");
                     }
                  }

                  WTSFreeMemory(User); 
               }

               WTSFreeMemory(SessionInfo);
            }
         }
         finally
         {
            WTSCloseServer(ServerHandle);
         }
      }

      public static bool SessionExists(String ServerName, String Username)
      {
         IntPtr ServerHandle = IntPtr.Zero;
         bool sessionExists = false;

         if (ServerName != null & ServerName != "localhost")
         {
            ServerHandle = WTSOpenServer(ServerName);
         }

         try
         {
            IntPtr SessionInfo = IntPtr.Zero;
            uint SessionCount = 0;
            Int32 retEnum = WTSEnumerateSessions(ServerHandle, 0, 1, ref SessionInfo, ref SessionCount);
            IntPtr CurrentSession = SessionInfo;

            if (retEnum != 0)
            {
               Int32 DataSize = Marshal.SizeOf(typeof(WTS_SESSION_INFO));
               IntPtr User = IntPtr.Zero;
               uint bytes = 0;

               for (int i = 0; i < SessionCount; i++)
               {
                  WTS_SESSION_INFO SI = (WTS_SESSION_INFO)Marshal.PtrToStructure((System.IntPtr)CurrentSession, typeof(WTS_SESSION_INFO));
                  CurrentSession += DataSize;

                  WTSQuerySessionInformation(ServerHandle, SI.SessionID, WTS_INFO_CLASS.WTSUserName, out User, out bytes);

                  if (String.Equals(Marshal.PtrToStringAnsi(User), Username, StringComparison.OrdinalIgnoreCase))
                  {
                     sessionExists = true;
                     WTSFreeMemory(User);
                     break;
                  }

                  WTSFreeMemory(User); 
               }

               WTSFreeMemory(SessionInfo);
            }
         }
         finally
         {
            WTSCloseServer(ServerHandle);
         }

         return sessionExists;
      }
   }
}
