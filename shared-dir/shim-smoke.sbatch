#!/bin/sh
#
#SBATCH --job-name=shim-smoke
#SBATCH --output=shim-smoke.%J.out
#SBATCH --time=00:01:00
#SBATCH --partition=quantum
#SBATCH --nodes=1
#SBATCH --gres=qpu:1
#
# Smoke test for Pass 1 of the QPU front-end shim wiring.
# Confirms inside a SLURM-launched process that:
#   - api_qpm.qpu_frontend (Protocol + Frontend) imports
#   - svc_iqm_qpm.drivers.native_iqm_driver imports
#   - QRC builds a Frontend with NativeIqmDriver and routes via Frontend
# Uses a stub client so we don't need real IQM credentials.

set -e

echo "[`date`] shim-smoke on `hostname`"

source /opt/qfw/qhpc/QFw/setup/qfw_activate
source "${QFW_IMAGE_VENV}/bin/activate"

python - <<'PY'
from api_qpm.qpu_frontend import QFwDeviceDriver, Frontend
from svc_iqm_qpm.drivers.native_iqm_driver import NativeIqmDriver
import svc_iqm_qpm.drivers.native_iqm_driver as nim

class StubClient:
    def get_backend_info(self): return {"backend": "stub", "where": "slurm"}
    def get_device_info(self): return {"id": "stub-q20", "where": "slurm"}
    def get_dynamic_backend_info(self, c=None): return {}
    def get_calibration_snapshot(self, c=None): return {}
    def get_coupling_graph(self, c=None): return []
    def run_circuit(self, c): return {}
    def get_last_job_timing(self, c=None): return {}
    def get_last_job_metadata(self, c=None): return {}

# Patch so QRC's default constructor uses the stub.
nim.IQMServiceClient = lambda: StubClient()

from svc_iqm_qpm.svc_qrc import QRC

print("[shim-smoke] importing protocol + Frontend:        OK")
print("[shim-smoke] importing NativeIqmDriver:            OK")
qrc = QRC(start=False)
print("[shim-smoke] QRC constructed via Frontend:         OK")
print("[shim-smoke] QRC.frontend.primary type:           ", type(qrc.frontend.primary).__name__)
print("[shim-smoke] isinstance(primary, QFwDeviceDriver):", isinstance(qrc.frontend.primary, QFwDeviceDriver))
print("[shim-smoke] qrc.get_device_info():               ", qrc.get_device_info())
print("[shim-smoke] qrc.get_backend_info():              ", qrc.get_backend_info())
print()
print("PASS 1 SHIM SMOKE: PASS")
PY

echo "[`date`] shim-smoke done on `hostname`"
