from fastapi.testclient import TestClient
from datetime import date
from app.main import app
from app.core.security import get_current_user
from app.schemas.user import UserProfileResponse

client = TestClient(app)

USER_A = UserProfileResponse(
    id="user-a-1111",
    email="user.a@mio.app",
    first_name="Usuario",
    last_name="Uno",
    role="trainer",
    profile_image_url=None,
    created_at=None,
    updated_at=None,
)

USER_B = UserProfileResponse(
    id="user-b-2222",
    email="user.b@mio.app",
    first_name="Usuario",
    last_name="Dos",
    role="trainer",
    profile_image_url=None,
    created_at=None,
    updated_at=None,
)


def test_get_records_unauthorized():
    """Verifica que solicitar PRs sin token devuelva 401 o 403."""
    res = client.get("/api/v1/records")
    assert res.status_code in (401, 403)


def test_create_record_unauthorized():
    """Verifica que crear un PR sin token devuelva 401 o 403."""
    res = client.post(
        "/api/v1/records",
        json={"exercise_name": "Sentadilla Trasera", "weight_kg": 100.0, "reps": 3},
    )
    assert res.status_code in (401, 403)


def test_create_and_get_records_authenticated():
    """Verifica creación y consulta de PRs para un usuario autenticado."""
    app.dependency_overrides[get_current_user] = lambda: USER_A
    try:
        # Crear PR
        payload = {
            "exercise_name": "Sentadilla Trasera",
            "exercise_id": "ex-001",
            "weight_kg": 140.0,
            "reps": 3,
            "record_date": str(date.today()),
            "notes": "Excelente técnica, sintiendo fuerza",
        }
        create_res = client.post("/api/v1/records", json=payload)
        assert create_res.status_code == 201
        created_data = create_res.json()
        assert created_data["exercise_name"] == "Sentadilla Trasera"
        assert created_data["weight_kg"] == 140.0
        assert created_data["reps"] == 3
        assert created_data["user_id"] == USER_A.id
        assert "id" in created_data

        # Consultar PRs del usuario
        get_res = client.get("/api/v1/records")
        assert get_res.status_code == 200
        records = get_res.json()
        assert isinstance(records, list)
        assert any(r["id"] == created_data["id"] for r in records)
    finally:
        app.dependency_overrides.clear()


def test_create_record_validation_invalid_weight():
    """Verifica que peso <= 0 retorne error de validación (422)."""
    app.dependency_overrides[get_current_user] = lambda: USER_A
    try:
        res = client.post(
            "/api/v1/records",
            json={"exercise_name": "Press de Banca", "weight_kg": 0, "reps": 5},
        )
        assert res.status_code == 422
    finally:
        app.dependency_overrides.clear()


def test_records_isolation_between_users():
    """Verifica que un usuario no pueda ver los PRs creados por otro usuario."""
    # Usuario A crea su récord
    app.dependency_overrides[get_current_user] = lambda: USER_A
    try:
        res_a = client.post(
            "/api/v1/records",
            json={"exercise_name": "Peso Muerto", "weight_kg": 200.0, "reps": 1},
        )
        assert res_a.status_code == 201
        pr_id_a = res_a.json()["id"]
    finally:
        app.dependency_overrides.clear()

    # Usuario B consulta sus propios récords
    app.dependency_overrides[get_current_user] = lambda: USER_B
    try:
        res_b = client.get("/api/v1/records")
        assert res_b.status_code == 200
        records_b = res_b.json()
        # El récord del Usuario A no debe aparecer en la lista del Usuario B
        assert not any(r["id"] == pr_id_a for r in records_b)
    finally:
        app.dependency_overrides.clear()


def test_get_records_progression_unauthorized():
    """Verifica que solicitar la progresión sin token devuelva 401 o 403."""
    res = client.get("/api/v1/records/progression")
    assert res.status_code in (401, 403)


def test_get_records_progression_authenticated_and_delta():
    """Verifica que los PRs se agrupen correctamente por ejercicio y reps, calculando deltas y orden cronológico."""
    USER_PROG = UserProfileResponse(
        id="user-prog-9999",
        email="prog@mio.app",
        first_name="Prog",
        last_name="User",
        role="trainer",
        profile_image_url=None,
        created_at=None,
        updated_at=None,
    )
    app.dependency_overrides[get_current_user] = lambda: USER_PROG
    try:
        # Carga 1: Press de Banca 5 reps - 80 kg
        res1 = client.post(
            "/api/v1/records",
            json={
                "exercise_name": "Press de Banca",
                "weight_kg": 80.0,
                "reps": 5,
                "record_date": "2026-09-01",
            },
        )
        assert res1.status_code == 201

        # Carga 2: Press de Banca 5 reps - 85 kg (subió peso)
        res2 = client.post(
            "/api/v1/records",
            json={
                "exercise_name": "Press de Banca",
                "weight_kg": 85.0,
                "reps": 5,
                "record_date": "2026-09-15",
            },
        )
        assert res2.status_code == 201

        # Carga 3: Press de Banca 1 rep - 100 kg (distintas reps)
        res3 = client.post(
            "/api/v1/records",
            json={
                "exercise_name": "Press de Banca",
                "weight_kg": 100.0,
                "reps": 1,
                "record_date": "2026-09-20",
            },
        )
        assert res3.status_code == 201

        # Carga 4: Sentadilla 3 reps - 120 kg (otro ejercicio)
        res4 = client.post(
            "/api/v1/records",
            json={
                "exercise_name": "Sentadilla",
                "weight_kg": 120.0,
                "reps": 3,
                "record_date": "2026-09-10",
            },
        )
        assert res4.status_code == 201

        # Consultar endpoint de progresión
        prog_res = client.get("/api/v1/records/progression")
        assert prog_res.status_code == 200
        groups = prog_res.json()
        assert isinstance(groups, list)
        assert len(groups) == 3

        # Buscar el grupo de Press de Banca 5 reps
        bench_5 = next(
            g for g in groups if g["exercise_name"] == "Press de Banca" and g["reps"] == 5
        )
        assert bench_5["current_pr_weight"] == 85.0
        assert bench_5["previous_weight"] == 80.0
        assert bench_5["delta_kg"] == 5.0
        assert len(bench_5["history"]) == 2
        assert bench_5["history"][0]["weight_kg"] == 80.0
        assert bench_5["history"][1]["weight_kg"] == 85.0

        # Buscar el grupo de Press de Banca 1 rep (solo 1 registro -> sin previous ni delta)
        bench_1 = next(
            g for g in groups if g["exercise_name"] == "Press de Banca" and g["reps"] == 1
        )
        assert bench_1["current_pr_weight"] == 100.0
        assert bench_1["previous_weight"] is None
        assert bench_1["delta_kg"] is None
        assert len(bench_1["history"]) == 1

        # Sentadilla 3 reps
        squat_3 = next(
            g for g in groups if g["exercise_name"] == "Sentadilla" and g["reps"] == 3
        )
        assert squat_3["current_pr_weight"] == 120.0
        assert squat_3["delta_kg"] is None
    finally:
        app.dependency_overrides.clear()


def test_update_record_flow():
    """Valida edición exitosa, validaciones de campo y aislamiento entre usuarios."""
    app.dependency_overrides[get_current_user] = lambda: USER_A
    try:
        # 1. Crear un récord
        create_res = client.post(
            "/api/v1/records",
            json={
                "exercise_name": "Curl de Bíceps",
                "weight_kg": 20.0,
                "reps": 10,
                "record_date": "2026-09-01",
            },
        )
        assert create_res.status_code == 201
        rec_id = create_res.json()["id"]

        # 2. Modificar peso y repeticiones
        update_res = client.put(
            f"/api/v1/records/{rec_id}",
            json={"weight_kg": 22.5, "reps": 8, "notes": "Subí el peso con buena técnica"},
        )
        assert update_res.status_code == 200
        updated = update_res.json()
        assert updated["weight_kg"] == 22.5
        assert updated["reps"] == 8
        assert updated["notes"] == "Subí el peso con buena técnica"

        # 3. Validación de peso inválido
        invalid_res = client.put(
            f"/api/v1/records/{rec_id}",
            json={"weight_kg": -5.0},
        )
        assert invalid_res.status_code in (400, 422)

        # 4. Intentar actualizar desde otro usuario (USER_B) -> 404
        app.dependency_overrides[get_current_user] = lambda: USER_B
        forbidden_update = client.put(
            f"/api/v1/records/{rec_id}",
            json={"weight_kg": 30.0},
        )
        assert forbidden_update.status_code == 404
    finally:
        app.dependency_overrides.clear()


def test_delete_record_flow():
    """Valida eliminación exitosa y aislamiento de borrado entre usuarios."""
    app.dependency_overrides[get_current_user] = lambda: USER_A
    try:
        # 1. Crear un récord
        create_res = client.post(
            "/api/v1/records",
            json={
                "exercise_name": "Fondos en Paralelas",
                "weight_kg": 15.0,
                "reps": 8,
                "record_date": "2026-09-05",
            },
        )
        assert create_res.status_code == 201
        rec_id = create_res.json()["id"]

        # 2. Intentar borrar desde otro usuario (USER_B) -> 404
        app.dependency_overrides[get_current_user] = lambda: USER_B
        forbidden_del = client.delete(f"/api/v1/records/{rec_id}")
        assert forbidden_del.status_code == 404

        # 3. Borrar con el dueño legítimo (USER_A) -> 204
        app.dependency_overrides[get_current_user] = lambda: USER_A
        del_res = client.delete(f"/api/v1/records/{rec_id}")
        assert del_res.status_code == 204

        # 4. Verificar que ya no aparece en el listado
        list_res = client.get("/api/v1/records")
        assert list_res.status_code == 200
        assert not any(r["id"] == rec_id for r in list_res.json())
    finally:
        app.dependency_overrides.clear()


