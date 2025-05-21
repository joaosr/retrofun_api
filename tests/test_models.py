import pytest
from sqlalchemy.ext.asyncio import AsyncSession
from retrofun.models import Product
from sqlalchemy import select


@pytest.mark.asyncio
async def test_product(session: AsyncSession) -> None:
    q = (
        select(Product)
        .where(Product.year == 1983)
        .order_by(Product.name.asc())
        .limit(3)
    )
    r = await session.scalars(q)
    assert r.all() == []
