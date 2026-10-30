// Wait until the DOM is fully loaded
document.addEventListener("DOMContentLoaded", () => {

    /* ===================================================
       1. FORM VALIDATION & SUCCESS ALERT
       =================================================== */
    const laundryForm = document.querySelector("form");

    if (laundryForm) {
        laundryForm.addEventListener("submit", (e) => {
            const phoneInput = document.getElementById("phone");
            const pickupDateInput = document.getElementById("pickupDate");

            // Simple phone length check
            if (phoneInput && phoneInput.value.trim().length < 10) {
                e.preventDefault();
                alert("Please enter a valid phone number (at least 10 digits).");
                phoneInput.focus();
                return;
            }

            // Ensure pickup date is not in the past
            if (pickupDateInput && pickupDateInput.value) {
                const selectedDate = new Date(pickupDateInput.value);
                const today = new Date();
                today.setHours(0, 0, 0, 0);

                if (selectedDate < today) {
                    e.preventDefault();
                    alert("Please select a valid pickup date today or in the future.");
                    pickupDateInput.focus();
                    return;
                }
            }

            // If validation passes, show a confirmation message
            alert("Thank you! Your Aqualine Laundry request has been submitted.");
        });
    }


    /* ===================================================
       2. LIVE SEARCH / FILTER FOR SERVICE TABLES
       =================================================== */
    const searchInput = document.getElementById("tableSearch");
    const tableRows = document.querySelectorAll("tbody tr");

    if (searchInput && tableRows.length > 0) {
        searchInput.addEventListener("keyup", () => {
            const query = searchInput.value.toLowerCase().trim();

            tableRows.forEach(row => {
                const text = row.textContent.toLowerCase();
                if (text.includes(query)) {
                    row.style.display = "";
                } else {
                    row.style.display = "none";
                }
            });
        });
    }

// Auto-set min date for pickup to today
const pickupDateInput = document.getElementById("pickupDate");
if (pickupDateInput) {
    const todayStr = new Date().toISOString().split("T")[0];
    pickupDateInput.setAttribute("min", todayStr);
}
// Replace alert with a smooth on-page success banner
const laundryForm = document.querySelector("form");
if (laundryForm) {
    laundryForm.addEventListener("submit", (e) => {
        e.preventDefault(); // Stop page refresh for demo purposes

        // Create success banner element
        const banner = document.createElement("div");
        banner.style.cssText = "background: #2EC4B6; color: white; padding: 15px; border-radius: 6px; margin-bottom: 20px; text-align: center; font-weight: bold;";
        banner.textContent = "Success! Your Aqualine Laundry order has been booked. We'll call you shortly.";

        // Insert at the top of the form
        laundryForm.prepend(banner);
        laundryForm.reset();

        // Remove banner after 5 seconds
        setTimeout(() => banner.remove(), 5000);
    });
}
    /* ===================================================
       3. QUICK PRICE CALCULATOR
       =================================================== */
    const weightInput = document.getElementById("calcWeight");
    const serviceSelect = document.getElementById("calcService");
    const totalOutput = document.getElementById("calcTotal");

    function calculateEstimate() {
        if (!weightInput || !serviceSelect || !totalOutput) return;

        const weight = parseFloat(weightInput.value) || 0;
        const rate = parseFloat(serviceSelect.value) || 0;
        const total = weight * rate;

        totalOutput.textContent = `KES ${total.toLocaleString()}`;
    }

    if (weightInput && serviceSelect) {
        weightInput.addEventListener("input", calculateEstimate);
        serviceSelect.addEventListener("change", calculateEstimate);
    }
});
/* ===================================================
       CONTACT PAGE FORM VALIDATION & SUCCESS ALERT
       =================================================== */
    const contactForm = document.getElementById("contactForm");

    if (contactForm) {
        contactForm.addEventListener("submit", (e) => {
            e.preventDefault(); // Prevent page reload for demo

            const phoneInput = document.getElementById("phoneNumber");
            const fullNameInput = document.getElementById("fullName");

            // Validate phone number length
            if (phoneInput && phoneInput.value.trim().length < 10) {
                alert("Please enter a valid phone number (at least 10 digits).");
                phoneInput.focus();
                return;
            }

            // Create and show success confirmation
            const successMsg = document.createElement("div");
            successMsg.style.cssText = "background: #2EC4B6; color: white; padding: 12px; border-radius: 5px; margin-bottom: 15px; text-align: center; font-weight: bold; font-size: 14px;";
            successMsg.textContent = `Thank you, ${fullNameInput.value}! Your message has been received. We'll reach out shortly.`;

            contactForm.prepend(successMsg);
            contactForm.reset();

            // Remove message after 5 seconds
            setTimeout(() => successMsg.remove(), 5000);
        });
    }