-- 授予对特定数据库的连接权限
GRANT CONNECT ON DATABASE uplion TO uplion;

-- 切换到目标数据库
\c your_database_name

-- 授予在public模式中创建表的权限
GRANT CREATE ON SCHEMA public TO uplion;

-- 授予对现有表的所有权限
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO uplion;

-- 授予对未来创建的表的所有权限
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO uplion;