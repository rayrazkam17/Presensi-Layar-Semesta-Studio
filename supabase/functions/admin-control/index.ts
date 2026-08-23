import {
  createClient,
} from "npm:@supabase/supabase-js@2";

import {
  corsHeaders,
} from "npm:@supabase/supabase-js@2/cors";

// ===========================================================
// JSON RESPONSE
// ===========================================================

function jsonResponse(
  body: Record<string, unknown>,
  status = 200,
) {
  return Response.json(
    body,
    {
      status,
      headers: {
        ...corsHeaders,
      },
    },
  );
}

// ===========================================================
// EDGE FUNCTION
// ===========================================================

export default {
  async fetch(req: Request) {
    // =======================================================
    // CORS PREFLIGHT
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

    // =======================================================
    // ONLY POST
    // =======================================================

    if (req.method !== "POST") {
      return jsonResponse(
        {
          ok: false,
          message:
            "Method tidak diizinkan.",
        },
        405,
      );
    }

    try {
      // =====================================================
      // ENVIRONMENT
      // =====================================================

      const supabaseUrl =
        Deno.env.get(
          "SUPABASE_URL",
        );

      const serviceRoleKey =
        Deno.env.get(
          "SUPABASE_SERVICE_ROLE_KEY",
        );

      if (!supabaseUrl) {
        return jsonResponse(
          {
            ok: false,
            message:
              "SUPABASE_URL tidak tersedia.",
          },
          500,
        );
      }

      if (!serviceRoleKey) {
        return jsonResponse(
          {
            ok: false,
            message:
              "SUPABASE_SERVICE_ROLE_KEY tidak tersedia.",
          },
          500,
        );
      }

      // =====================================================
      // GET AUTH HEADER
      // =====================================================

      const authHeader =
        req.headers.get(
          "Authorization",
        );

      if (
        !authHeader ||
        !authHeader.startsWith(
          "Bearer ",
        )
      ) {
        return jsonResponse(
          {
            ok: false,
            message:
              "Session login tidak ditemukan.",
          },
          401,
        );
      }

      const token =
        authHeader.substring(
          7,
        );

      // =====================================================
      // ADMIN SUPABASE CLIENT
      // =====================================================

      const adminClient =
        createClient(
          supabaseUrl,
          serviceRoleKey,
          {
            auth: {
              autoRefreshToken:
                false,

              persistSession:
                false,
            },
          },
        );

      // =====================================================
      // VERIFY CALLER USER
      // =====================================================

      const {
        data: currentUserData,
        error: currentUserError,
      } =
        await adminClient.auth
          .getUser(
            token,
          );

      if (
        currentUserError ||
        !currentUserData.user
      ) {
        console.error(
          "AUTH ERROR:",
          currentUserError,
        );

        return jsonResponse(
          {
            ok: false,
            message:
              "Session login tidak valid.",
          },
          401,
        );
      }

      const currentUser =
        currentUserData.user;

      // =====================================================
      // CHECK ADMIN PROFILE
      // =====================================================

      const {
        data: callerProfile,
        error: callerProfileError,
      } =
        await adminClient
          .from(
            "profiles",
          )
          .select(
            "id, nama, role",
          )
          .eq(
            "id",
            currentUser.id,
          )
          .maybeSingle();

      if (callerProfileError) {
        console.error(
          "PROFILE ERROR:",
          callerProfileError,
        );

        return jsonResponse(
          {
            ok: false,
            message:
              "Gagal membaca profile administrator.",
          },
          500,
        );
      }

      if (!callerProfile) {
        return jsonResponse(
          {
            ok: false,
            message:
              "Profile administrator tidak ditemukan.",
          },
          403,
        );
      }

      if (
        callerProfile.role !==
        "admin"
      ) {
        return jsonResponse(
          {
            ok: false,
            message:
              "Akses ditolak. Hanya administrator.",
          },
          403,
        );
      }

      // =====================================================
      // BODY
      // =====================================================

      let body:
        Record<string, unknown>;

      try {
        body =
          await req.json();
      } catch {
        return jsonResponse(
          {
            ok: false,
            message:
              "Request body tidak valid.",
          },
          400,
        );
      }

      const action =
        body.action
          ?.toString()
          .trim();

      if (!action) {
        return jsonResponse(
          {
            ok: false,
            message:
              "Action wajib diberikan.",
          },
          400,
        );
      }

      console.log(
        "ADMIN ACTION:",
        action,
        "BY:",
        currentUser.id,
      );

      // =====================================================
      // LIST EMPLOYEES
      // =====================================================

      if (
        action ===
        "list_employees"
      ) {
        const {
          data: profiles,
          error: profilesError,
        } =
          await adminClient
            .from(
              "profiles",
            )
            .select(
              "id, nama, role",
            )
            .eq(
              "role",
              "user",
            )
            .order(
              "nama",
              {
                ascending: true,
              },
            );

        if (profilesError) {
          throw profilesError;
        }

        const {
          data: usersData,
          error: usersError,
        } =
          await adminClient
            .auth
            .admin
            .listUsers({
              page: 1,
              perPage: 1000,
            });

        if (usersError) {
          throw usersError;
        }

        finalEmployeeLoop:
        for (const profile of profiles ?? []) {
          void profile;
          break finalEmployeeLoop;
        }

        const employees =
          (profiles ?? []).map(
            (profile) => {
              const authUser =
                usersData.users.find(
                  (user) =>
                    user.id ===
                    profile.id,
                );

              return {
                id:
                  profile.id,

                nama:
                  profile.nama ??
                  "Pegawai",

                role:
                  profile.role,

                email:
                  authUser?.email ??
                  "-",

                created_at:
                  authUser
                    ?.created_at ??
                  null,

                last_sign_in_at:
                  authUser
                    ?.last_sign_in_at ??
                  null,
              };
            },
          );

        return jsonResponse({
          ok: true,
          employees,
        });
      }

      // =====================================================
      // CREATE EMPLOYEE
      // =====================================================

      if (
        action ===
        "create_employee"
      ) {
        const nama =
          body.nama
            ?.toString()
            .trim();

        const email =
          body.email
            ?.toString()
            .trim()
            .toLowerCase();

        const password =
          body.password
            ?.toString();

        if (
          !nama ||
          nama.length < 2
        ) {
          return jsonResponse(
            {
              ok: false,
              message:
                "Nama pegawai belum valid.",
            },
            400,
          );
        }

        if (
          !email ||
          !email.includes("@")
        ) {
          return jsonResponse(
            {
              ok: false,
              message:
                "Email belum valid.",
            },
            400,
          );
        }

        if (
          !password ||
          password.length < 8
        ) {
          return jsonResponse(
            {
              ok: false,
              message:
                "Password minimal 8 karakter.",
            },
            400,
          );
        }

        const {
          data: createData,
          error: createError,
        } =
          await adminClient
            .auth
            .admin
            .createUser({
              email,
              password,

              email_confirm:
                true,

              user_metadata: {
                nama,
                role:
                  "user",
              },
            });

        if (
          createError ||
          !createData.user
        ) {
          return jsonResponse(
            {
              ok: false,
              message:
                createError
                  ?.message ??
                "Gagal membuat akun pegawai.",
            },
            400,
          );
        }

        const newUser =
          createData.user;

        const {
          error:
            profileInsertError,
        } =
          await adminClient
            .from(
              "profiles",
            )
            .insert({
              id:
                newUser.id,

              nama,

              role:
                "user",
            });

        if (
          profileInsertError
        ) {
          // Rollback Auth user.
          await adminClient
            .auth
            .admin
            .deleteUser(
              newUser.id,
            );

          return jsonResponse(
            {
              ok: false,
              message:
                "Profile pegawai gagal dibuat: "
                +
                profileInsertError
                  .message,
            },
            500,
          );
        }

        return jsonResponse({
          ok: true,

          message:
            "Akun pegawai berhasil dibuat.",

          employee: {
            id:
              newUser.id,

            nama,

            email,

            role:
              "user",
          },
        });
      }

      // =====================================================
      // RESET PASSWORD
      // =====================================================

      if (
        action ===
        "reset_password"
      ) {
        const userId =
          body.user_id
            ?.toString()
            .trim();

        const newPassword =
          body.new_password
            ?.toString();

        if (!userId) {
          return jsonResponse(
            {
              ok: false,
              message:
                "User ID tidak ditemukan.",
            },
            400,
          );
        }

        if (
          !newPassword ||
          newPassword.length < 8
        ) {
          return jsonResponse(
            {
              ok: false,
              message:
                "Password baru minimal 8 karakter.",
            },
            400,
          );
        }

        const {
          data: targetProfile,
          error: targetError,
        } =
          await adminClient
            .from(
              "profiles",
            )
            .select(
              "id, nama, role",
            )
            .eq(
              "id",
              userId,
            )
            .maybeSingle();

        if (
          targetError ||
          !targetProfile
        ) {
          return jsonResponse(
            {
              ok: false,
              message:
                "Pegawai tidak ditemukan.",
            },
            404,
          );
        }

        if (
          targetProfile.role !==
          "user"
        ) {
          return jsonResponse(
            {
              ok: false,
              message:
                "Password administrator tidak dapat "
                + "diubah dari menu pegawai.",
            },
            403,
          );
        }

        const {
          error: updateError,
        } =
          await adminClient
            .auth
            .admin
            .updateUserById(
              userId,
              {
                password:
                  newPassword,
              },
            );

        if (updateError) {
          return jsonResponse(
            {
              ok: false,
              message:
                updateError.message,
            },
            400,
          );
        }

        return jsonResponse({
          ok: true,
          message:
            "Password pegawai berhasil diubah.",
        });
      }

      // =====================================================
      // DELETE ATTENDANCE
      // =====================================================

      if (
        action ===
        "delete_attendance"
      ) {
        const attendanceId =
          body.attendance_id
            ?.toString()
            .trim();

        if (!attendanceId) {
          return jsonResponse(
            {
              ok: false,
              message:
                "Attendance ID tidak ditemukan.",
            },
            400,
          );
        }

        const {
          data: attendance,
          error:
            attendanceError,
        } =
          await adminClient
            .from(
              "attendance",
            )
            .select(
              "id, user_id, attendance_date",
            )
            .eq(
              "id",
              attendanceId,
            )
            .maybeSingle();

        if (
          attendanceError ||
          !attendance
        ) {
          return jsonResponse(
            {
              ok: false,
              message:
                "Data absensi tidak ditemukan.",
            },
            404,
          );
        }

        const {
          error: deleteError,
        } =
          await adminClient
            .from(
              "attendance",
            )
            .delete()
            .eq(
              "id",
              attendanceId,
            );

        if (deleteError) {
          throw deleteError;
        }

        return jsonResponse({
          ok: true,
          message:
            "Data absensi berhasil dihapus.",
        });
      }

      // =====================================================
      // DELETE EMPLOYEE
      // =====================================================

      if (
        action ===
        "delete_employee"
      ) {
        const userId =
          body.user_id
            ?.toString()
            .trim();

        if (!userId) {
          return jsonResponse(
            {
              ok: false,
              message:
                "User ID pegawai tidak ditemukan.",
            },
            400,
          );
        }

        // Admin tidak dapat menghapus dirinya sendiri.
        if (
          userId ===
          currentUser.id
        ) {
          return jsonResponse(
            {
              ok: false,
              message:
                "Administrator tidak dapat "
                + "menghapus akun sendiri.",
            },
            403,
          );
        }

        // ===================================================
        // CHECK TARGET
        // ===================================================

        const {
          data: targetProfile,
          error:
            targetProfileError,
        } =
          await adminClient
            .from(
              "profiles",
            )
            .select(
              "id, nama, role",
            )
            .eq(
              "id",
              userId,
            )
            .maybeSingle();

        if (
          targetProfileError ||
          !targetProfile
        ) {
          return jsonResponse(
            {
              ok: false,
              message:
                "Profile pegawai tidak ditemukan.",
            },
            404,
          );
        }

        if (
          targetProfile.role !==
          "user"
        ) {
          return jsonResponse(
            {
              ok: false,
              message:
                "Akun administrator tidak dapat "
                + "dihapus dari menu pegawai.",
            },
            403,
          );
        }

        const employeeName =
          targetProfile.nama ??
          "Pegawai";

        // ===================================================
        // DELETE ATTENDANCE
        // ===================================================

        const {
          error:
            deleteAttendanceError,
        } =
          await adminClient
            .from(
              "attendance",
            )
            .delete()
            .eq(
              "user_id",
              userId,
            );

        if (
          deleteAttendanceError
        ) {
          throw deleteAttendanceError;
        }

        // ===================================================
        // DELETE PROFILE
        // ===================================================

        const {
          error:
            deleteProfileError,
        } =
          await adminClient
            .from(
              "profiles",
            )
            .delete()
            .eq(
              "id",
              userId,
            );

        if (
          deleteProfileError
        ) {
          throw deleteProfileError;
        }

        // ===================================================
        // DELETE AUTH USER
        // ===================================================

        const {
          error:
            deleteAuthError,
        } =
          await adminClient
            .auth
            .admin
            .deleteUser(
              userId,
            );

        if (
          deleteAuthError
        ) {
          throw deleteAuthError;
        }

        return jsonResponse({
          ok: true,

          message:
            `Akun ${employeeName} berhasil dihapus permanen.`,
        });
      }

      // =====================================================
      // UNKNOWN ACTION
      // =====================================================

      return jsonResponse(
        {
          ok: false,
          message:
            `Action "${action}" tidak dikenali.`,
        },
        400,
      );
    } catch (error) {
      console.error(
        "ADMIN CONTROL ERROR:",
        error,
      );

      return jsonResponse(
        {
          ok: false,

          message:
            error instanceof Error
              ? error.message
              : "Terjadi kesalahan server.",
        },
        500,
      );
    }
  },
};