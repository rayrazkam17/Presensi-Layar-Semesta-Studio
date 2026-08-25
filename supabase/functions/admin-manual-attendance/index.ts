import { createClient } from "npm:@supabase/supabase-js@2";
import { corsHeaders } from "npm:@supabase/supabase-js@2/cors";

function response(
  body: Record<string, unknown>,
  status = 200,
) {
  return Response.json(body, {
    status,
    headers: {
      ...corsHeaders,
    },
  });
}

function pad(value: number) {
  return value.toString().padStart(2, "0");
}

export default {
  async fetch(req: Request) {
    // =======================================================
    // CORS
    // =======================================================

    if (req.method === "OPTIONS") {
      return Response.json(
        {
          ok: true,
        },
        {
          headers: corsHeaders,
        },
      );
    }

    if (req.method !== "POST") {
      return response(
        {
          ok: false,
          message: "Method tidak diizinkan.",
        },
        405,
      );
    }

    try {
      // =====================================================
      // ENV
      // =====================================================

      const supabaseUrl =
        Deno.env.get("SUPABASE_URL");

      const serviceRoleKey =
        Deno.env.get(
          "SUPABASE_SERVICE_ROLE_KEY",
        );

      if (
        !supabaseUrl ||
        !serviceRoleKey
      ) {
        return response(
          {
            ok: false,
            message:
              "Konfigurasi Supabase server tidak ditemukan.",
          },
          500,
        );
      }

      // =====================================================
      // ADMIN CLIENT
      // =====================================================

      const adminClient =
        createClient(
          supabaseUrl,
          serviceRoleKey,
          {
            auth: {
              autoRefreshToken: false,
              persistSession: false,
            },
          },
        );

      // =====================================================
      // VERIFY JWT
      // =====================================================

      const authorization =
        req.headers.get(
          "Authorization",
        );

      if (
        !authorization ||
        !authorization.startsWith(
          "Bearer ",
        )
      ) {
        return response(
          {
            ok: false,
            message:
              "Token login tidak ditemukan.",
          },
          401,
        );
      }

      const token =
        authorization.replace(
          "Bearer ",
          "",
        );

      const {
        data: userData,
        error: userError,
      } =
        await adminClient.auth.getUser(
          token,
        );

      if (
        userError ||
        !userData.user
      ) {
        return response(
          {
            ok: false,
            message:
              "Session login tidak valid.",
          },
          401,
        );
      }

      const adminUser =
        userData.user;

      // =====================================================
      // CHECK ADMIN ROLE
      // =====================================================

      const {
        data: adminProfile,
        error: adminProfileError,
      } =
        await adminClient
          .from("profiles")
          .select(
            "id, nama, role",
          )
          .eq(
            "id",
            adminUser.id,
          )
          .maybeSingle();

      if (
        adminProfileError ||
        !adminProfile
      ) {
        return response(
          {
            ok: false,
            message:
              "Profile admin tidak ditemukan.",
          },
          403,
        );
      }

      if (
        adminProfile.role
          ?.toString()
          .toLowerCase() !==
        "admin"
      ) {
        return response(
          {
            ok: false,
            message:
              "Akses hanya diperbolehkan untuk admin.",
          },
          403,
        );
      }

      // =====================================================
      // BODY
      // =====================================================

      const body =
        await req.json();

      const userId =
        body.user_id
          ?.toString()
          .trim();

      const attendanceDate =
        body.attendance_date
          ?.toString()
          .trim();

      const checkIn =
        body.check_in
          ?.toString()
          .trim();

      const checkOut =
        body.check_out
          ?.toString()
          .trim();

      const reason =
        body.reason
          ?.toString()
          .trim();

      const note =
        body.note
          ?.toString()
          .trim() ?? "";

      const replaceExisting =
        body.replace_existing === true;

      // =====================================================
      // VALIDATION
      // =====================================================

      if (
        !userId ||
        !attendanceDate ||
        !checkIn ||
        !checkOut ||
        !reason
      ) {
        return response(
          {
            ok: false,
            message:
              "Data presensi manual belum lengkap.",
          },
          400,
        );
      }

      const dateRegex =
        /^\d{4}-\d{2}-\d{2}$/;

      const timeRegex =
        /^\d{2}:\d{2}$/;

      if (
        !dateRegex.test(
          attendanceDate,
        )
      ) {
        return response(
          {
            ok: false,
            message:
              "Format tanggal tidak valid.",
          },
          400,
        );
      }

      if (
        !timeRegex.test(checkIn) ||
        !timeRegex.test(checkOut)
      ) {
        return response(
          {
            ok: false,
            message:
              "Format jam tidak valid.",
          },
          400,
        );
      }

      // =====================================================
      // CHECK EMPLOYEE
      // =====================================================

      const {
        data: employee,
        error: employeeError,
      } =
        await adminClient
          .from("profiles")
          .select(
            "id, nama, role",
          )
          .eq(
            "id",
            userId,
          )
          .maybeSingle();

      if (
        employeeError ||
        !employee
      ) {
        return response(
          {
            ok: false,
            message:
              "Pegawai tidak ditemukan.",
          },
          404,
        );
      }

      if (
        employee.role
          ?.toString()
          .toLowerCase() !==
        "user"
      ) {
        return response(
          {
            ok: false,
            message:
              "Presensi manual hanya dapat diberikan kepada pegawai.",
          },
          400,
        );
      }

      // =====================================================
      // WIB DATE
      //
      // Input admin dianggap WIB / UTC+7.
      // =====================================================

      const checkInDate =
        new Date(
          `${attendanceDate}T${checkIn}:00+07:00`,
        );

      const checkOutDate =
        new Date(
          `${attendanceDate}T${checkOut}:00+07:00`,
        );

      if (
        Number.isNaN(
          checkInDate.getTime(),
        ) ||
        Number.isNaN(
          checkOutDate.getTime(),
        )
      ) {
        return response(
          {
            ok: false,
            message:
              "Tanggal atau jam tidak valid.",
          },
          400,
        );
      }

      if (
        checkOutDate.getTime() <=
        checkInDate.getTime()
      ) {
        return response(
          {
            ok: false,
            message:
              "Jam keluar harus setelah jam masuk.",
          },
          400,
        );
      }

      // =====================================================
      // CALCULATE WORK HOURS
      // =====================================================

      const differenceMs =
        checkOutDate.getTime() -
        checkInDate.getTime();

      const totalHours =
        differenceMs /
        1000 /
        60 /
        60;

      // Aturan default:
      // > 8 jam dianggap overtime.
      //
      // Kalau aturan perusahaan berbeda,
      // angka ini nanti bisa disesuaikan.
      const normalHours =
        8;

      const overtimeHours =
        totalHours > normalHours
          ? totalHours - normalHours
          : 0;

      const isOvertime =
        overtimeHours > 0;

      // =====================================================
      // EXISTING ATTENDANCE
      // =====================================================

      const {
        data: existingAttendance,
        error: existingError,
      } =
        await adminClient
          .from("attendance")
          .select(
            `
            id,
            user_id,
            attendance_date,
            check_in,
            check_out,
            check_in_photo,
            check_out_photo
            `,
          )
          .eq(
            "user_id",
            userId,
          )
          .eq(
            "attendance_date",
            attendanceDate,
          )
          .maybeSingle();

      if (existingError) {
        throw existingError;
      }

      // =====================================================
      // DATA
      // =====================================================

      const attendanceData = {
        user_id:
          userId,

        attendance_date:
          attendanceDate,

        check_in:
          checkInDate.toISOString(),

        check_out:
          checkOutDate.toISOString(),

        total_work_hours:
          Number(
            totalHours.toFixed(2),
          ),

        overtime_hours:
          Number(
            overtimeHours.toFixed(2),
          ),

        is_overtime:
          isOvertime,

        is_auto_checkout:
          false,

        is_manual:
          true,

        manual_reason:
          reason,

        manual_note:
          note || null,

        manual_created_by:
          adminUser.id,

        manual_created_at:
          new Date().toISOString(),
      };

      // =====================================================
      // EXISTING DATA FOUND
      // =====================================================

      if (existingAttendance) {
        if (!replaceExisting) {
          return response(
            {
              ok: false,

              code:
                "attendance_exists",

              message:
                `Presensi ${employee.nama} pada tanggal ${attendanceDate} sudah ada.`,

              existing_attendance:
                existingAttendance,
            },
          );
        }

        // ===================================================
        // UPDATE EXISTING
        //
        // Foto lama TIDAK dihapus.
        // Kalau sebelumnya ada foto asli, tetap dipertahankan.
        // ===================================================

        const {
          data: updatedAttendance,
          error: updateError,
        } =
          await adminClient
            .from("attendance")
            .update(
              attendanceData,
            )
            .eq(
              "id",
              existingAttendance.id,
            )
            .select()
            .single();

        if (updateError) {
          throw updateError;
        }

        return response({
          ok: true,

          mode:
            "updated",

          message:
            `Presensi ${employee.nama} berhasil diperbarui oleh admin.`,

          attendance:
            updatedAttendance,
        });
      }

      // =====================================================
      // INSERT NEW MANUAL ATTENDANCE
      //
      // FOTO DIKOSONGKAN.
      // =====================================================

      const {
        data: insertedAttendance,
        error: insertError,
      } =
        await adminClient
          .from("attendance")
          .insert({
            ...attendanceData,

            check_in_photo:
              null,

            check_out_photo:
              null,
          })
          .select()
          .single();

      if (insertError) {
        throw insertError;
      }

      return response({
        ok: true,

        mode:
          "inserted",

        message:
          `Presensi manual ${employee.nama} berhasil ditambahkan.`,

        attendance:
          insertedAttendance,
      });
    } catch (error) {
      console.error(
        "admin-manual-attendance:",
        error,
      );

      return response(
        {
          ok: false,

          message:
            error instanceof Error
              ? error.message
              : "Terjadi kesalahan pada server.",
        },
        500,
      );
    }
  },
};