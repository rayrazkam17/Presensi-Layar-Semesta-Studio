import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, apikey, content-type",
  "Access-Control-Allow-Methods":
    "POST, OPTIONS",
};

// =====================================================
// Helper
// =====================================================

function safeDate(value: unknown): Date | null {
  if (!value) return null;

  const date = new Date(String(value));

  if (isNaN(date.getTime())) {
    return null;
  }

  return date;
}

function formatTanggal(date: Date | null): string {
  if (date == null) return "-";

  return date.toLocaleDateString("id-ID", {
    day: "numeric",
    month: "long",
    year: "numeric",
    timeZone: "Asia/Jakarta",
  });
}

function formatJam(date: Date | null): string {
  if (date == null) return "-";

  return date.toLocaleTimeString("id-ID", {
    hour: "2-digit",
    minute: "2-digit",
    hour12: false,
    timeZone: "Asia/Jakarta",
  });
}

function formatDurasi(hours: unknown): string {
  const totalHour = Number(hours ?? 0);

  if (isNaN(totalHour)) {
    return "-";
  }

  const totalMinutes = Math.round(totalHour * 60);

  const jam = Math.floor(totalMinutes / 60);
  const menit = totalMinutes % 60;

  if (jam == 0) {
    return `${menit} menit`;
  }

  if (menit == 0) {
    return `${jam} jam`;
  }

  return `${jam} jam ${menit} menit`;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", {
      headers: corsHeaders,
    });
  }

  try {
    const body = await req.json();

    console.log("================================");
    console.log("BODY DARI FLUTTER");
    console.log("================================");
    console.log(body);

    const token = Deno.env.get("FONTEE_TOKEN");
    const target = Deno.env.get("FONTEE_TARGET");

    if (!token) {
      throw new Error("FONTEE_TOKEN belum diset.");
    }

    if (!target) {
      throw new Error("FONTEE_TARGET belum diset.");
    }

    let message = "";

    switch (body.type) {
      case "checkin": {
        const checkIn = safeDate(body.checkIn);

        message = `🏢 LAYAR SEMESTA


    📋 PRESENSI MASUK

    👤 Nama
    ${body.nama}

    📅 Tanggal
    ${formatTanggal(checkIn)}

    🕗 Jam Masuk
    ${formatJam(checkIn)} WIB`;

        // Tambahkan link foto jika ada
        if (body.photoUrl) {
          message += `

    📸 Bukti Presensi

    🔗 ${body.photoUrl}`;
        }

        message += `

    ✅ CHECK IN BERHASIL

`;

        break;
      }

      case "checkout": {
        const checkIn = safeDate(body.checkIn);
        const checkOut = safeDate(body.checkOut);

        message = `🏢 LAYAR SEMESTA


    📋 PRESENSI PULANG

    👤 Nama
    ${body.nama}

    📅 Tanggal
    ${formatTanggal(checkOut)}

    🕗 Jam Masuk
    ${formatJam(checkIn)} WIB

    🕔 Jam Pulang
    ${formatJam(checkOut)} WIB

    ⏱ Durasi
    ${formatDurasi(body.totalWorkHours)}

    💼 Lembur
    ${Number(body.overtimeHours ?? 0) > 0 ? "Ya" : "Tidak"}`;

        // Tambahkan link foto jika ada
        if (body.photoUrl) {
          message += `

    📸 Bukti Checkout

    🔗 ${body.photoUrl}`;
        }

        message += `

    ✅ CHECK OUT BERHASIL

`;

        break;
      }

      case "auto_checkout": {
        const tanggal = safeDate(body.tanggal);

        message = `🏢 LAYAR SEMESTA


    ⚠ AUTO CHECK OUT

    👤 Nama
    ${body.nama}

    📅 Tanggal
    ${formatTanggal(tanggal)}

    ⚠ Belum checkout.

    Sistem otomatis melakukan checkout otomatis.`;

        // Jika suatu saat auto checkout juga memiliki foto
        if (body.photoUrl) {
          message += `

    📸 Bukti Presensi

    🔗 ${body.photoUrl}`;
        }

        message += `

`;

        break;
      }

      default:
        throw new Error(`Type tidak dikenali : ${body.type}`);
    }

    console.log("================================");
    console.log("MESSAGE");
    console.log("================================");
    console.log(message);

    console.log("================================");
    console.log("TARGET");
    console.log("================================");
    console.log(target);

    const bodyData = new URLSearchParams();

    bodyData.append("target", target);
    bodyData.append("message", message);

    const response = await fetch(
      "https://api.fonnte.com/send",
      {
        method: "POST",
        headers: {
          Authorization: token,
          "Content-Type": "application/x-www-form-urlencoded",
        },
        body: bodyData.toString(),
      },
    );

    console.log("================================");
    console.log("HTTP STATUS");
    console.log("================================");
    console.log(response.status);

    console.log("================================");
    console.log("HTTP OK");
    console.log("================================");
    console.log(response.ok);

    const rawResult = await response.text();

    console.log("================================");
    console.log("RAW RESPONSE FONNTE");
    console.log("================================");
    console.log(rawResult);

    let result;

    try {
      result = JSON.parse(rawResult);
    } catch (_) {
      result = rawResult;
    }

    console.log("================================");
    console.log("PARSED RESPONSE");
    console.log("================================");
    console.log(result);

    return Response.json(
      {
        success: response.ok,
        status: response.status,
        result,
      },
      {
        headers: corsHeaders,
      },
    );
  } catch (e) {
    console.error("================================");
    console.error("ERROR EDGE FUNCTION");
    console.error("================================");
    console.error(e);

    return Response.json(
      {
        success: false,
        error: e instanceof Error
            ? e.message
            : String(e),
      },
      {
        status: 500,
        headers: corsHeaders,
      },
    );
  }
});