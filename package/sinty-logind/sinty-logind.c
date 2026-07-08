/* sinty-logind -- minimal org.freedesktop.login1 shim for sinit (no systemd/logind).
 *
 * The desktop shell drives power via login1 D-Bus (SessionManager -> Manager.Reboot/
 * PowerOff/Suspend, Session.Terminate). Without logind those calls die -> power buttons
 * do nothing (FB-17). This root daemon owns org.freedesktop.login1 on the system bus and
 * maps the Manager power methods to sinit's /bin/reboot|poweroff and the kernel suspend.
 *
 * Authorization: real logind gates these via polkit (only the active local session). We
 * have no session tracking, but we MUST NOT let any process on the bus power off the
 * machine (a system daemon or background task could DoS it). So the action methods are
 * gated to the caller's uid: root or a human user (uid >= UID_MIN); system-service uids
 * (1..UID_MIN-1) are denied. The desktop user (uid >= 1000) keeps working (FB-17); the
 * pre-login greeter reboots via its own `systemctl` path, not this socket.
 */
#include <gio/gio.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>

#define UID_MIN 1000u

static const char *xml =
  "<node>"
  "  <interface name='org.freedesktop.login1.Manager'>"
  "    <method name='Reboot'><arg type='b' name='interactive' direction='in'/></method>"
  "    <method name='PowerOff'><arg type='b' name='interactive' direction='in'/></method>"
  "    <method name='Halt'><arg type='b' name='interactive' direction='in'/></method>"
  "    <method name='Suspend'><arg type='b' name='interactive' direction='in'/></method>"
  "    <method name='CanReboot'><arg type='s' name='result' direction='out'/></method>"
  "    <method name='CanPowerOff'><arg type='s' name='result' direction='out'/></method>"
  "    <method name='CanSuspend'><arg type='s' name='result' direction='out'/></method>"
  "  </interface>"
  "</node>";

/* Session object at /org/freedesktop/login1/session/self: the shell logs out via
 * Session.Terminate. We end the caller's graphical session by killing its labwc (the
 * greetd session leader) -> greetd returns to the greeter. */
static const char *sxml =
  "<node>"
  "  <interface name='org.freedesktop.login1.Session'>"
  "    <method name='Terminate'/>"
  "    <method name='Lock'/>"
  "    <method name='Unlock'/>"
  "  </interface>"
  "</node>";

/* ask the bus daemon for the sender's uid; (uid_t)-1 on failure -> treated as unauthorized */
static uid_t caller_uid(GDBusConnection *c, const char *sender) {
  if (!sender) return (uid_t)-1;
  GError *e = NULL;
  GVariant *r = g_dbus_connection_call_sync(
      c, "org.freedesktop.DBus", "/org/freedesktop/DBus", "org.freedesktop.DBus",
      "GetConnectionUnixUser", g_variant_new("(s)", sender), G_VARIANT_TYPE("(u)"),
      G_DBUS_CALL_FLAGS_NONE, 2000, NULL, &e);
  if (!r) { if (e) g_error_free(e); return (uid_t)-1; }
  guint32 uid = (guint32)-1;
  g_variant_get(r, "(u)", &uid);
  g_variant_unref(r);
  return (uid_t)uid;
}

static void method(GDBusConnection *c, const char *sender, const char *path,
                   const char *iface, const char *m, GVariant *params,
                   GDBusMethodInvocation *inv, gpointer u) {
  (void)path; (void)iface; (void)params; (void)u;
  int is_action = !strcmp(m, "Reboot") || !strcmp(m, "PowerOff") ||
                  !strcmp(m, "Halt") || !strcmp(m, "Suspend");
  if (is_action) {
    uid_t uid = caller_uid(c, sender);
    /* allow root and human users; deny system-service uids and unknown callers */
    if (uid != 0 && (uid == (uid_t)-1 || (unsigned)uid < UID_MIN)) {
      g_dbus_method_invocation_return_error(
          inv, G_DBUS_ERROR, G_DBUS_ERROR_ACCESS_DENIED,
          "not authorized to %s (caller uid %u)", m, (unsigned)uid);
      return;
    }
  }
  if (!strcmp(m, "Reboot")) {
    g_dbus_method_invocation_return_value(inv, NULL);
    if (system("/bin/reboot") != 0) (void)!system("reboot");
  } else if (!strcmp(m, "PowerOff") || !strcmp(m, "Halt")) {
    g_dbus_method_invocation_return_value(inv, NULL);
    if (system("/bin/poweroff") != 0) (void)!system("poweroff");
  } else if (!strcmp(m, "Suspend")) {
    g_dbus_method_invocation_return_value(inv, NULL);
    (void)!system("echo mem > /sys/power/state");
  } else if (!strncmp(m, "Can", 3)) {
    g_dbus_method_invocation_return_value(inv, g_variant_new("(s)", "yes"));
  } else {
    g_dbus_method_invocation_return_value(inv, NULL);
  }
}
static const GDBusInterfaceVTable vt = { method, NULL, NULL, { 0 } };

static void session_method(GDBusConnection *c, const char *sender, const char *path,
                           const char *iface, const char *m, GVariant *params,
                           GDBusMethodInvocation *inv, gpointer u) {
  (void)path; (void)iface; (void)params; (void)u;
  if (!strcmp(m, "Terminate")) {
    uid_t uid = caller_uid(c, sender);
    /* same gate as the power actions: only a human user or root may end a session */
    if (uid != 0 && (uid == (uid_t)-1 || (unsigned)uid < UID_MIN)) {
      g_dbus_method_invocation_return_error(inv, G_DBUS_ERROR, G_DBUS_ERROR_ACCESS_DENIED,
          "not authorized to Terminate (caller uid %u)", (unsigned)uid);
      return;
    }
    g_dbus_method_invocation_return_value(inv, NULL);
    /* end the graphical session by killing labwc (the greetd session leader) -> greetd
     * returns to the greeter. BusyBox pkill matches against the full command line, so
     * -x would require the whole argv "/usr/bin/labwc" and never matches the bare name
     * (proven live: pkill -x labwc = no match, pkill labwc = kills it). Match by name
     * substring; on this single-user desktop the only labwc is the caller's compositor.
     * The uid gate above already restricts who may trigger this. */
    (void)!system("pkill -TERM labwc");
  } else {
    /* Lock/Unlock: acknowledged no-ops (the shell drives the lockscreen itself) */
    g_dbus_method_invocation_return_value(inv, NULL);
  }
}
static const GDBusInterfaceVTable svt = { session_method, NULL, NULL, { 0 } };

static void on_bus(GDBusConnection *c, const char *name, gpointer u) {
  (void)name; (void)u;
  GDBusNodeInfo *ni = g_dbus_node_info_new_for_xml(xml, NULL);
  if (ni) g_dbus_connection_register_object(c, "/org/freedesktop/login1",
              ni->interfaces[0], &vt, NULL, NULL, NULL);
  GDBusNodeInfo *si = g_dbus_node_info_new_for_xml(sxml, NULL);
  if (si) g_dbus_connection_register_object(c, "/org/freedesktop/login1/session/self",
              si->interfaces[0], &svt, NULL, NULL, NULL);
}
int main(void) {
  g_bus_own_name(G_BUS_TYPE_SYSTEM, "org.freedesktop.login1",
                 G_BUS_NAME_OWNER_FLAGS_REPLACE, on_bus, NULL, NULL, NULL, NULL);
  g_main_loop_run(g_main_loop_new(NULL, FALSE));
  return 0;
}
